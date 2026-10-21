import AppKit

enum ProjectTemplateType: String, CaseIterable {
    case application
    case program
//    case template

    var title: String {
        switch self {
        case .application: "Application"
        case .program: "Program"
//        case .template: "Select from Template"
        }
    }

    var subtitle: String {
        switch self {
        case .application:
            "Create a new application project."
        case .program:
            "Create a standalone program."
//        case .template:
//            "Start with an existing project template."
        }
    }

    var symbolName: String {
        switch self {
        case .application: "app"
        case .program: "chevron.left.forwardslash.chevron.right"
//        case .template: "folder"
        }
    }
}

struct ProjectTemplateSelection {
    let type: ProjectTemplateType
    let name: String
    let language: String
}
