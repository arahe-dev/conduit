import Foundation
import SwiftData

enum DemoIDs {
    static let work = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
    static let chores = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
    static let personal = UUID(uuidString: "00000000-0000-4000-8000-000000000003")!

    static let deepWork = UUID(uuidString: "00000000-0000-4000-8000-000000000011")!
    static let research = UUID(uuidString: "00000000-0000-4000-8000-000000000012")!
    static let email = UUID(uuidString: "00000000-0000-4000-8000-000000000013")!
}

enum DemoDataSeeder {
    static func seedIfNeeded(context: ModelContext, force: Bool = false) throws {
        let existing = try context.fetch(FetchDescriptor<Space>())
        if !existing.isEmpty && !force {
            return
        }
        if force {
            for space in existing {
                context.delete(space)
            }
        }

        let work = Space(
            id: DemoIDs.work,
            name: "Work",
            tint: .orange,
            displayOrder: 0,
            focusKeyword: "Work",
            icon: .work
        )
        work.tasks = [
            TaskItem(id: DemoIDs.deepWork, name: "Deep Work", displayOrder: 0, space: work),
            TaskItem(id: DemoIDs.research, name: "Research", displayOrder: 1, space: work),
            TaskItem(id: DemoIDs.email, name: "Email", displayOrder: 2, space: work)
        ]
        work.defaultTaskID = DemoIDs.deepWork

        let chores = Space(
            id: DemoIDs.chores,
            name: "Chores",
            tint: .teal,
            displayOrder: 1,
            focusKeyword: "Personal",
            icon: .chores
        )
        chores.tasks = [
            TaskItem(name: "Kitchen", displayOrder: 0, space: chores),
            TaskItem(name: "Laundry", displayOrder: 1, space: chores),
            TaskItem(name: "Errands", displayOrder: 2, space: chores)
        ]

        let personal = Space(
            id: DemoIDs.personal,
            name: "Personal",
            tint: .purple,
            displayOrder: 2,
            icon: .personal
        )
        personal.tasks = [
            TaskItem(name: "Reading", displayOrder: 0, space: personal),
            TaskItem(name: "Planning", displayOrder: 1, space: personal)
        ]

        context.insert(work)
        context.insert(chores)
        context.insert(personal)
        try context.save()
    }
}
