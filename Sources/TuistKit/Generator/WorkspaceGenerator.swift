import Basic
import Foundation
import TuistCore
import xcodeproj

protocol WorkspaceGenerating: AnyObject {
    @discardableResult
    func generate(path: AbsolutePath, graph: Graphing, options: GenerationOptions, directory: GenerationDirectory) throws -> AbsolutePath
}

final class WorkspaceGenerator: WorkspaceGenerating {
    // MARK: - Attributes

    let projectGenerator: ProjectGenerating
    let system: Systeming
    let printer: Printing
    let resourceLocator: ResourceLocating
    let projectDirectoryHelper: ProjectDirectoryHelping

    // MARK: - Init

    convenience init(system: Systeming = System(),
                     printer: Printing = Printer(),
                     resourceLocator: ResourceLocating = ResourceLocator(),
                     projectDirectoryHelper: ProjectDirectoryHelping = ProjectDirectoryHelper()) {
        self.init(system: system,
                  printer: printer,
                  resourceLocator: resourceLocator,
                  projectDirectoryHelper: projectDirectoryHelper,
                  projectGenerator: ProjectGenerator(printer: printer,
                                                     system: system,
                                                     resourceLocator: resourceLocator))
    }

    init(system: Systeming,
         printer: Printing,
         resourceLocator: ResourceLocating,
         projectDirectoryHelper: ProjectDirectoryHelping,
         projectGenerator: ProjectGenerating) {
        self.system = system
        self.printer = printer
        self.resourceLocator = resourceLocator
        self.projectDirectoryHelper = projectDirectoryHelper
        self.projectGenerator = projectGenerator
    }

    // MARK: - WorkspaceGenerating

    @discardableResult
    func generate(path: AbsolutePath,
                  graph: Graphing,
                  options: GenerationOptions,
                  directory: GenerationDirectory = .manifest) throws -> AbsolutePath {
        let workspaceRootPath = try projectDirectoryHelper.setupDirectory(name: graph.name,
                                                                          path: graph.entryPath,
                                                                          directory: directory)
        let workspaceName = "\(graph.name).xcworkspace"
        printer.print(section: "Generating workspace \(workspaceName)")
        let workspacePath = workspaceRootPath.appending(component: workspaceName)
        let workspaceData = XCWorkspaceData(children: [])
        let workspace = XCWorkspace(data: workspaceData)

        try graph.projects.forEach { project in
            let sourceRootPath = try projectDirectoryHelper.setupProjectDirectory(project: project,
                                                                                  directory: directory)
            let generatedProject = try projectGenerator.generate(project: project,
                                                                 options: options,
                                                                 graph: graph,
                                                                 sourceRootPath: sourceRootPath)

            let relativePath = generatedProject.path.relative(to: path)
            let location = XCWorkspaceDataElementLocationType.group(relativePath.asString)
            let fileRef = XCWorkspaceDataFileRef(location: location)
            workspace.data.children.append(XCWorkspaceDataElement.file(fileRef))
        }
        try workspace.write(path: workspacePath.path, override: true)

        return workspacePath
    }
}
