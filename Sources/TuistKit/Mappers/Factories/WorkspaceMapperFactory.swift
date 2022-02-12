import Foundation
import TSCBasic
import TSCUtility
import TuistAutomation
import TuistCore
import TuistGenerator
import TuistGraph

protocol WorkspaceMapperFactorying {
    /// Returns the default workspace mapper.
    /// - Returns: A workspace mapping instance.
    func `default`(config: Config) -> [WorkspaceMapping]

    /// Returns a mapper to generate cacheable prorjects.
    /// - Parameter config: The project configuration.
    /// - Parameter includedTargets: The list of targets to cache.
    /// - Returns: A workspace mapping instance.
    func cache(config: Config, includedTargets: Set<String>) -> [WorkspaceMapping]

    /// Returns a mapper for automation commands like build and test.
    /// - Parameter config: The project configuration.
    /// - Parameter workspaceDirectory: The directory where the workspace will be generated.
    /// - Returns: A workspace mapping instance.
    func automation(config: Config, workspaceDirectory: AbsolutePath) -> [WorkspaceMapping]
}

final class WorkspaceMapperFactory: WorkspaceMapperFactorying {
    private let projectMapper: ProjectMapping

    init(projectMapper: ProjectMapping) {
        self.projectMapper = projectMapper
    }

    func cache(config: Config, includedTargets: Set<String>) -> [WorkspaceMapping] {
        var mappers = self.default(config: config, forceWorkspaceSchemes: false)
        mappers += [GenerateCacheableSchemesWorkspaceMapper(includedTargets: includedTargets)]
        return mappers
    }

    func automation(config: Config, workspaceDirectory: AbsolutePath) -> [WorkspaceMapping] {
        var mappers: [WorkspaceMapping] = []
        mappers.append(AutomationPathWorkspaceMapper(workspaceDirectory: workspaceDirectory))
        mappers += self.default(config: config, forceWorkspaceSchemes: true)

        return mappers
    }

    func `default`(config: Config) -> [WorkspaceMapping] {
        self.default(config: config, forceWorkspaceSchemes: false)
    }

    private func `default`(config: Config, forceWorkspaceSchemes: Bool) -> [WorkspaceMapping] {
        var mappers: [WorkspaceMapping] = []

        mappers.append(
            ProjectWorkspaceMapper(mapper: projectMapper)
        )

        mappers.append(
            TuistWorkspaceIdentifierMapper()
        )

        mappers.append(
            IDETemplateMacrosMapper()
        )

        mappers.append(
            AutogeneratedWorkspaceSchemeWorkspaceMapper(forceWorkspaceSchemes: forceWorkspaceSchemes)
        )

        mappers.append(
            ModuleMapMapper()
        )

        if let lastUpgradeVersion = config.generationOptions.lastXcodeUpgradeCheck {
            mappers.append(
                LastUpgradeVersionWorkspaceMapper(
                    lastUpgradeVersion: lastUpgradeVersion
                )
            )
        }

        return mappers
    }
}
