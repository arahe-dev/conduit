import Foundation
import SwiftData

enum PersistenceController {
    static func makeContainer(inMemory: Bool, storeURL: URL? = nil) throws -> ModelContainer {
        let schema = Schema([
            Space.self,
            TaskItem.self,
            Session.self,
            TaskInterval.self
        ])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let storeURL {
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
