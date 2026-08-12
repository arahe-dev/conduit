import Foundation

enum SpaceImportError: Error, Equatable, LocalizedError {
    case malformedJSON
    case missingName
    case emptyTasks
    case excessiveTaskCount
    case invalidColor(String)
    case emptyTaskName

    var errorDescription: String? {
        switch self {
        case .malformedJSON:
            return "The Space definition is not valid JSON."
        case .missingName:
            return "A Space name is required."
        case .emptyTasks:
            return "A Space must include at least one task."
        case .excessiveTaskCount:
            return "A Space cannot include more than 40 tasks."
        case .invalidColor(let value):
            return "Unsupported color '\(value)'."
        case .emptyTaskName:
            return "Task names cannot be empty."
        }
    }
}

struct SpaceImportPayload: Equatable, Sendable {
    var name: String
    var color: SpaceTint
    var tasks: [String]

    static let maxTasks = 40
    static let maxNameLength = 80

    static func parse(json: String) throws -> SpaceImportPayload {
        let data = Data(json.utf8)
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw SpaceImportError.malformedJSON
        }
        guard let dict = object as? [String: Any] else {
            throw SpaceImportError.malformedJSON
        }
        return try parse(dictionary: dict)
    }

    static func parse(dictionary: [String: Any]) throws -> SpaceImportPayload {
        guard let rawName = dictionary["name"] as? String else {
            throw SpaceImportError.missingName
        }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            throw SpaceImportError.missingName
        }
        let clippedName = String(name.prefix(maxNameLength))

        let color: SpaceTint
        if let rawColor = dictionary["color"] as? String {
            color = try SpaceTint.parse(rawColor)
        } else {
            color = .blue
        }

        guard let rawTasks = dictionary["tasks"] as? [Any] else {
            throw SpaceImportError.emptyTasks
        }
        var tasks: [String] = []
        var seen = Set<String>()
        for item in rawTasks {
            guard let value = item as? String else {
                throw SpaceImportError.emptyTaskName
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                throw SpaceImportError.emptyTaskName
            }
            let key = trimmed.lowercased()
            if seen.contains(key) {
                continue
            }
            seen.insert(key)
            tasks.append(String(trimmed.prefix(maxNameLength)))
        }
        if tasks.isEmpty {
            throw SpaceImportError.emptyTasks
        }
        if tasks.count > maxTasks {
            throw SpaceImportError.excessiveTaskCount
        }
        return SpaceImportPayload(name: clippedName, color: color, tasks: tasks)
    }
}
