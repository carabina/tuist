import Foundation
@testable import TuistKit

final class MockCommandCheck: CommandChecking {
    var checkStub: ((String) throws -> Void)?

    func check(command: String) throws {
        try checkStub?(command)
    }
}
