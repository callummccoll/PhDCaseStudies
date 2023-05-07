import Foundation
import Gateways
import KripkeStructure
import KripkeStructureViews
import Timers
import XCTest

@testable import Verification

open class KripkeStructureTestCase: XCTestCase {

    open var readableName: String {
#if os(macOS)
        self.name.dropFirst(2).dropLast().components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
#else
        self.name.components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
#endif
    }

    open var originalPath: String!

    open var testFolder: URL!

    open override func setUpWithError() throws {
        let fm = FileManager.default
        originalPath = fm.currentDirectoryPath
        let filePath = URL(fileURLWithPath: #filePath, isDirectory: false)
        testFolder = filePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("kripke_structures", isDirectory: true)
            .appendingPathComponent(readableName, isDirectory: true)
        _ = try? fm.removeItem(atPath: testFolder.path)
        try fm.createDirectory(at: testFolder, withIntermediateDirectories: true)
        fm.changeCurrentDirectoryPath(testFolder.path)
    }

    open override func tearDownWithError() throws {
        let fm = FileManager.default
        fm.changeCurrentDirectoryPath(originalPath)
    }

    public func generate(
        gateway: StackGateway,
        threads: [IsolatedThread],
        clock: FSMClock,
        cycleLength: UInt
    ) throws {
        let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                parameterisedThreads: [:],
                cycleLength: cycleLength
            )
        )
        let viewFactory = AggregateKripkeStructureViewFactory(factories: [
            AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory()),
            AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory())
        ])
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: testFolder.path)
        try verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
            try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
        }
    }

}
