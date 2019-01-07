//
//  Skeleton+Commands.swift
//  MurrayTests
//
//  Created by Stefano Mondino on 04/01/2019.
//

import Foundation
import Commander
import MurrayKit
extension Skeleton {

    static func commands(for group: Group) {
        group.group("skeleton") {
            $0.command(
                "new",
                Argument<String>("projectName", description: "Name of project"),
                Option<String>("git", default: "https://github.com/synesthesia-it/Skeleton.git", description: "Project's template git url")) {
                    projectName, git in
                    let repository = Repository(package: git)
                    try Skeleton(projectName: projectName, repository: repository).run()
            }
        }
    }
}