//
//  Bone.swift
//  MurrayCore
//
//  Created by Stefano Mondino on 16/07/18.
//

import Foundation
import Rainbow
class BoneList: Codable {

    class Bone: Codable {
        var name = ""

        var description: String {
            get { return _description ?? "" }
            set { _description = newValue}
        }
        var files: [String] {
            get {return _files ?? [] }
            set { _files = newValue }
        }
        var subBones: [String] {
            get { return _subBones ?? [] }
            set { _subBones = newValue }
        }

        var folders: [String] {
            get {return _folderPath?.components(separatedBy: "/") ?? [] }
            set { _folderPath = newValue.joined(separator: "/")}
        }

        var placeholder: String {
            get { return _placeholder ?? "Bone" }
            set { _placeholder = newValue }
        }
        var targetNames: [String] {
            get {return _targetNames ?? [] }
            set { _targetNames = newValue }
        }
        var createSubfolder: Bool {
            get { return _createSubfolder ?? true }
            set { _createSubfolder = newValue }
        }

        private var _createSubfolder: Bool?
        private var _subBones: [String]?
        private var _files: [String]?
        private var _folderPath: String?
        private var _description: String?
        private var _placeholder: String?
        private var _targetNames: [String]?

        enum CodingKeys: String, CodingKey {
            case _subBones = "subBones"
            case _files = "files"
            case name = "name"
            case _folderPath = "folderPath"
            case _placeholder = "placeholder"
            case _description = "description"
            case _targetNames = "targets"
            case _createSubfolder = "createSubfolder"
        }

        init(name: String, files: [String]) {
            self.name = name
            self.files = files.map { name + "/" + $0 }
            self.targetNames = []
            self.createSubfolder = true
            self.placeholder = "Bone"
            self.folders = []
            self.subBones = []
            self.description = "Automatically generated by Murray.\nContains \(files.joined(separator: ", "))"
        }
    }

    private var _bones: [Bone]
    lazy var bones: [String: Bone] = {
        return _bones.reduce([:], { a, b in
            var acc = a
            acc[b.name] = b
            return acc
        })
    }()
    func append(bone: Bone) {
        _bones = _bones + [bone]
    }
    var name: String = ""
    var sourcesBaseFolder: String = ""
    private var destinationBaseFolder: String = "Sources"
    var folders: [String] {
        get {
            return destinationBaseFolder.components(separatedBy: "/")

        }
    }
    var isLocal = false
    enum CodingKeys: String, CodingKey {
        case _bones = "bones"
        case name
        case destinationBaseFolder
        case sourcesBaseFolder
    }

    var printableDescription: String {
        return "\n" + self._bones
            .map { [$0.name.green, $0.description]
                .compactMap {$0}
                .joined(separator: " - ") }
            .joined(separator: "\n\n") + "\n"
    }

    private init() {
        self._bones = []
    }

    public static func list(name: String, bones: [Bone] = []) -> BoneList {
        let list = BoneList()
        list.name = name
        list.isLocal = true
        list.sourcesBaseFolder = ""
        list.bones = bones.reduce([:]) {
            var acc = $0
            acc[$1.name] = $1
            return $0
        }
        return list
    }

}
