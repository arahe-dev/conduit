import Foundation
import SwiftData

@MainActor
protocol SessionControlling: AnyObject {
    func start() throws
    func stop() throws
    func pause() throws
    func resume() throws
    func lap() throws
    func selectSpace(_ id: UUID)
    func distractionStarted()
    func distractionEnded()
}

@MainActor
final class AppRuntime {
    static let shared = AppRuntime()
    var sessionController: (any SessionControlling)?
    var container: ModelContainer?
    private init() {}
}
