import XCTest
@testable import WinMine98

@MainActor
final class GameModelTests: XCTestCase {
    func testWindowSizePresetsKeepTheOriginalPixelScale() {
        XCTAssertEqual(WindowSizePreset.small.title, "Small (Original)")
        XCTAssertEqual(WindowSizePreset.small.scale, 1)
        XCTAssertEqual(WindowSizePreset.medium.scale, 1.5)
        XCTAssertEqual(WindowSizePreset.large.scale, 2)
    }

    func testWindows98PresetSizes() {
        let model = GameModel()

        model.newGame(.beginner)
        XCTAssertEqual(model.width, 8)
        XCTAssertEqual(model.height, 8)
        XCTAssertEqual(model.mineCount, 10)

        model.newGame(.intermediate)
        XCTAssertEqual(model.width, 16)
        XCTAssertEqual(model.height, 16)
        XCTAssertEqual(model.mineCount, 40)

        model.newGame(.expert)
        XCTAssertEqual(model.width, 30)
        XCTAssertEqual(model.height, 16)
        XCTAssertEqual(model.mineCount, 99)
    }

    func testFirstClickIsSafeAndStartsGame() {
        let model = GameModel()
        model.newGame(.beginner)

        model.reveal(at: 0)

        XCTAssertFalse(model.cells[0].hasMine)
        XCTAssertTrue(model.cells[0].revealed)
        XCTAssertEqual(model.phase, .playing)
        XCTAssertEqual(model.cells.filter(\.hasMine).count, 10)
    }

    func testMarksCycleLikeClassicWindows() {
        let model = GameModel()
        model.newGame(.beginner)

        model.toggleMark(at: 1)
        XCTAssertEqual(model.cells[1].mark, .flag)
        XCTAssertEqual(model.remainingMineDisplay, 9)

        model.toggleMark(at: 1)
        XCTAssertEqual(model.cells[1].mark, .question)
        XCTAssertEqual(model.remainingMineDisplay, 10)

        model.toggleMark(at: 1)
        XCTAssertEqual(model.cells[1].mark, .none)
    }

    func testOpeningAllSafeCellsWinsAndFlagsMines() {
        let model = GameModel()
        model.newGame(.beginner)
        model.reveal(at: 0)

        for index in model.cells.indices where !model.cells[index].hasMine {
            model.reveal(at: index)
        }

        XCTAssertEqual(model.phase, .won)
        XCTAssertTrue(model.cells.filter(\.hasMine).allSatisfy { $0.mark == .flag })
        XCTAssertEqual(model.remainingMineDisplay, 0)
    }

    func testCustomFieldClampsToWindows98Limits() {
        let model = GameModel()
        model.newCustomGame(width: 100, height: 100, mines: 9999)

        XCTAssertEqual(model.width, 30)
        XCTAssertEqual(model.height, 24)
        XCTAssertEqual(model.mineCount, 719)
    }
}
