//
//  Template.swift
//  MurrayCore
//
//  Created by Stefano Mondino on 12/07/18.
//

import Foundation
import Files
import ShellOut
import Commander

class BoneList : Codable {
    
    class Bone : Codable {
        
        var subBones: [String] = []
        var files: [String]  = []
        var folders: [String] = []
        var createSubfolder:Bool = false
        
        enum CodingKeys : String, CodingKey {
            case subBones
            case files
            case folders
            case createSubfolder
        }
    }
    
    var bones: [String:Bone]
    var sourcesBaseFolder: String = ""
    
    enum CodingKeys : String, CodingKey {
        case bones
        case sourcesBaseFolder
    }
}


public final class Template {
    
    private enum Kind : String {
        case view
        case viewController
        
        var folders: [String] {
            switch self {
            case .view: return ["App","Views"]
            case .viewController: return ["App","ViewControllers"]
            }
        }
        var files: [String] {
            switch self {
            case .view: return ["ItemView.swift","ItemView.xib","ItemViewModel.swift"]
                .map { "Bone" + $0}
            case .viewController : return []
            }
        }
        var placeholder:String {
            return "Bone"
        }
        
    }
    
    
    static func commands(for group:Group) {
        group.group("template") {
            $0.command(
                "setup",
                //                Argument<String>("setup", description: "Setup templates in current folder"),
                Option<String>("git", default:"git@github.com:synesthesia-it/Bones.git", description:"Project's template git url"))
            {
                git in
                guard let url = URL(string: git) else {
                    return
                }
                try Template.setup(git: url)
                //try Template.setup(projectName: projectName, git: url).run()
            }
            $0.group("new") {
                $0.command("view",
                           Argument<String>("name",description:"")
                    )
                { name in
                    try Template.newTemplate(kind: .view, name: name)
                }
            }
        }
    }
    private static let murrayTemplatesFolderName = ".murrayTemplates"
    
    private static func setup(git:URL) throws {
        let fs = FileSystem()
        
        try? FileManager.default.removeItem(atPath: murrayTemplatesFolderName)
        
        //Check if root folder (look for a xcodeproj file)
        
        guard let folder = try? fs.createFolder(at: murrayTemplatesFolderName) else {
            throw Error.existingFolder
        }
        
        FileManager.default.changeCurrentDirectoryPath(folder.path)
        print ("Cloning bones app from \(git.absoluteString)")
        
        try shellOut(to:.gitClone(url:git))
        
        try? folder.subfolders.first?.moveContents(to: folder)
        
        guard let spec = try? folder.file(named: "Bonespec.json") else {
            throw Error.missingBonespec
        }
        guard let data = try? spec.read() else {
            throw Error.missingBonespec
        }
        
        guard let list = try? JSONDecoder().decode(BoneList.self, from: data) else {
            throw Error.bonespecParsingError
        }
        print (list)
        //move first folder's contents to root
    }
    
    private static func newTemplate(kind:Kind, name:String) throws {
        let fs = FileSystem()
        
        guard let templatesFolder = try? fs.currentFolder.subfolder(named: murrayTemplatesFolderName) else {
            throw Error.missingSetup
        }
        let scriptPath = "\(murrayTemplatesFolderName)/script.rb"
        FileManager.default.createFile(atPath: scriptPath, contents: nil, attributes: nil)
        let script = try File(path: scriptPath, using: FileManager.default)
        try script.write(string: Template.rubyScript)
        
        let subfolders = ["Sources"] + kind.folders
        let sourcesFolder:Folder? = subfolders.reduce(fs.currentFolder) { acc, current -> Folder? in
            guard let f = acc else { return nil }
            return try? f.subfolder(named:current)
        }
        guard let containingFolder = sourcesFolder else {
            throw Error.missingSubfolder
        }
        
        guard let finalFolder = try? containingFolder.createSubfolder(named: name) else {
            throw Error.missingSubfolder
        }
        
        try kind.files.forEach { filename in
            print (templatesFolder.path + "/" + filename )
            guard let templateFile = try? templatesFolder.file(named: filename) else {
                throw Error.missingFile
            }
            print ("Moving to destination")
            guard let file = try? templateFile.copy(to: finalFolder) else {
                throw Error.missingFile
            }
            print ("Renaming")
            try file.rename(to: filename.replacingOccurrences(of: kind.placeholder, with: name))
            print ("Reading file")
            var string = try file.readAsString()
            let innerPlaceholder = "___\(kind.placeholder)Placeholder___"
            let innerPlaceholderLowercased = "___\(kind.placeholder)PlaceholderFirstLowercased___"
            string = string
                .replacingOccurrences(of: innerPlaceholder, with: name)
                .replacingOccurrences(of: innerPlaceholderLowercased, with: name.firstLowercased())
            print ("Writing file")
            try file.write(string: string)
            //TODO find project name
            
            
            
            
            let args = [
                scriptPath,
                "test",
                file.path,
                "\"\((kind.folders + [name]).joined(separator:"|"))\""
            ]
            print (args)
            try shellOut(to: "ruby",
                         arguments:args)
            
        }
        
        
        
        
    }
    
}

fileprivate extension Template {
    static let rubyScript = """

        require 'xcodeproj'
        project_name = ARGV[0]
        file_path = ARGV[1]
        destination_folder_string = ARGV[2]
        targets_string = ARGV[3] || "App"

        destination_folders = destination_folder_string.split('|')
        target_names = targets_string.split('|')

        project_path = "./#{project_name}.xcodeproj"
        project = Xcodeproj::Project.open(project_path)

        reference = project['Sources']
        path = "./Sources"
        destination_folders.each do |f|
          path = path + "/" + f
          if reference[f] != nil
            reference = reference[f]
          else
            reference = reference.new_group(f, path, :project)
          end
        end

        file = Xcodeproj::Project::Object::FileReferencesFactory.new_reference(reference , file_path , :project)

        reference << file

        project.targets
                .select { |t| target_names.include?(t.name)}
                .each do |t|
                  t.source_build_phase.add_file_reference(file)
                end
        project.save

    """
}

public extension String {
    func firstLowercased() -> String {
        return self.prefix(1).lowercased() + self.dropFirst()
    }
}

public extension Template {
    enum Error: Swift.Error {
        case missingSetup
        case missingFile
        case missingSubfolder
        case missingProjectName
        case existingFolder
        case gitError
        case shellError
        case missingBonespec
        case bonespecParsingError
    }
}