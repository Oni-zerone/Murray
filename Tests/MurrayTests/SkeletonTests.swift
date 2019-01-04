//
//  ProjectTests.swift
//  MurrayTests
//
//  Created by Stefano Mondino on 03/01/2019.
//

import Foundation
import Quick
import Nimble
import Files
@testable import MurrayKit

class SkeletonSpec: QuickSpec {
    override func spec() {
        
        let projectName = "MurrayProjectTest"
        
        let fs = FileSystem()
        
        beforeEach {
            Logger.logLevel = .verbose
            //            DependencyManager.shared = TestDependency()
            
            //            let fileSystem = FileSystem()
            //            let tempFolder = fileSystem.temporaryFolder
            //            let testFolder = try! tempFolder.createSubfolderIfNeeded(
            //                withName: projectName
            //            )
            //            print (testFolder.path)
        }
        context("in real environment") {
            let url = URL(string: "https://github.com/synesthesia-it/Skeleton.git")!
            beforeEach {
                DependencyManager.reset()
            }
            describe("creating a new Project") {
                it("should clone a repository") {
                    try? fs.currentFolder.subfolder(atPath: projectName).delete()
                    let project = Skeleton(projectName: projectName, git: url)
                    let defaultFolder = FileManager.default.currentDirectoryPath
                    expect { try project.run() }.notTo(throwError())
                    expect(FileManager.default.currentDirectoryPath) == defaultFolder
            }
            }
        }
        context("in mocked environment") {
            let url = URL(string: "https://mocked.local")!
            beforeEach {
                DependencyManager.shared = TestDependency()
            }
            describe("creating a new Project") {
                beforeEach {
                    
                }
                it("should clone a repository") {
                    try? fs.currentFolder.subfolder(atPath: projectName).delete()
                    let project = Skeleton(projectName: projectName, git: url)
                    let defaultFolder = FileManager.default.currentDirectoryPath
                    expect { try project.run() }.notTo(throwError())
                    expect(FileManager.default.currentDirectoryPath) == defaultFolder
                    
                    let projectFolder = try? fs.currentFolder.subfolder(named: projectName)
                    expect(projectFolder).notTo(beNil())
                    expect(projectFolder?.containsSubfolder(named: "MurrayProjectTestTestFolder")) == true
                    expect(projectFolder?.containsSubfolder(named: "MurrayProjectTest.xcodeproj")) == true
                    expect(projectFolder?.containsSubfolder(named: "UntouchedTestFolder")) == true
                    expect(projectFolder?.containsSubfolder(named: ".git")) == true
                    let testFolder = try? projectFolder?.subfolder(named: "MurrayProjectTestTestFolder")
                    expect(testFolder).notTo(beNil())
                    
                    expect(testFolder??.containsFile(named: "MurrayProjectTestTestFile1.txt")) == true
                    expect(testFolder??.containsFile(named: "MurrayProjectTestTestFile2.txt")) == true
                    expect(testFolder??.containsFile(named: "UntouchedTestFile1.txt")) == true
                    
                }
                it ("should create a folder named \(projectName)") {
                    print (fs.currentFolder.path)
                    expect { try fs.currentFolder.subfolder(named: projectName) }.notTo(throwError())
                }
            }
            
        }
    }
}
