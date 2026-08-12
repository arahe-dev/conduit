import Foundation
import SwiftData

@MainActor
final class AppRuntime {
    static let shared = AppRuntime()
    var sessionController: SessionController?
    var container: ModelContainer?
    private init() {}
}
