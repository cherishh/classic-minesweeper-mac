import Foundation

enum Difficulty: String, CaseIterable {
    case beginner
    case intermediate
    case expert
    case custom

    var settings: (width: Int, height: Int, mines: Int) {
        switch self {
        case .beginner: return (8, 8, 10)
        case .intermediate: return (16, 16, 40)
        case .expert: return (30, 16, 99)
        case .custom: return (8, 8, 10)
        }
    }

    var menuTitle: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .expert: return "Expert"
        case .custom: return "Custom..."
        }
    }
}

enum GamePhase {
    case ready
    case playing
    case won
    case lost
}

enum CellMark {
    case none
    case flag
    case question
}

struct MineCell {
    var hasMine = false
    var revealed = false
    var mark: CellMark = .none
    var adjacentMines = 0
}

@MainActor
final class GameModel {
    private(set) var width = 8
    private(set) var height = 8
    private(set) var mineCount = 10
    private(set) var difficulty: Difficulty = .beginner
    private(set) var cells = Array(repeating: MineCell(), count: 64)
    private(set) var phase: GamePhase = .ready
    private(set) var elapsedSeconds = 0
    private(set) var explodedIndex: Int?

    var marksEnabled = true
    var colorsEnabled = true
    var onChange: (() -> Void)?
    var onWin: ((Difficulty, Int) -> Void)?

    private var timer: Timer?
    private var minesPlaced = false

    deinit {
        timer?.invalidate()
    }

    var flagCount: Int {
        cells.reduce(0) { $0 + ($1.mark == .flag ? 1 : 0) }
    }

    var remainingMineDisplay: Int {
        mineCount - flagCount
    }

    func newGame(_ difficulty: Difficulty) {
        let preset = difficulty.settings
        newGame(width: preset.width, height: preset.height, mines: preset.mines, difficulty: difficulty)
    }

    func newCustomGame(width: Int, height: Int, mines: Int) {
        let safeWidth = min(30, max(8, width))
        let safeHeight = min(24, max(8, height))
        let safeMines = min(safeWidth * safeHeight - 1, max(10, mines))
        newGame(width: safeWidth, height: safeHeight, mines: safeMines, difficulty: .custom)
    }

    private func newGame(width: Int, height: Int, mines: Int, difficulty: Difficulty) {
        stopTimer()
        self.width = width
        self.height = height
        self.mineCount = mines
        self.difficulty = difficulty
        cells = Array(repeating: MineCell(), count: width * height)
        phase = .ready
        elapsedSeconds = 0
        explodedIndex = nil
        minesPlaced = false
        onChange?()
    }

    func index(column: Int, row: Int) -> Int? {
        guard column >= 0, column < width, row >= 0, row < height else { return nil }
        return row * width + column
    }

    func neighbors(of index: Int) -> [Int] {
        let column = index % width
        let row = index / width
        var result: [Int] = []
        for dy in -1...1 {
            for dx in -1...1 where !(dx == 0 && dy == 0) {
                if let neighbor = self.index(column: column + dx, row: row + dy) {
                    result.append(neighbor)
                }
            }
        }
        return result
    }

    func toggleMark(at index: Int) {
        guard cells.indices.contains(index), !cells[index].revealed else { return }
        guard phase != .won, phase != .lost else { return }

        switch cells[index].mark {
        case .none:
            cells[index].mark = .flag
        case .flag:
            cells[index].mark = marksEnabled ? .question : .none
        case .question:
            cells[index].mark = .none
        }
        onChange?()
    }

    func reveal(at index: Int) {
        guard cells.indices.contains(index), phase != .won, phase != .lost else { return }
        guard !cells[index].revealed, cells[index].mark != .flag else { return }

        if !minesPlaced {
            placeMines(excluding: index)
            phase = .playing
            startTimer()
        }

        if cells[index].hasMine {
            cells[index].revealed = true
            explodedIndex = index
            phase = .lost
            stopTimer()
            revealMines()
            onChange?()
            return
        }

        floodReveal(from: index)
        checkForWin()
        onChange?()
    }

    func chord(at index: Int) {
        guard cells.indices.contains(index), cells[index].revealed else { return }
        guard cells[index].adjacentMines > 0, phase == .playing else { return }
        let around = neighbors(of: index)
        let flags = around.reduce(0) { $0 + (cells[$1].mark == .flag ? 1 : 0) }
        guard flags == cells[index].adjacentMines else { return }

        for neighbor in around where !cells[neighbor].revealed && cells[neighbor].mark != .flag {
            if cells[neighbor].hasMine {
                cells[neighbor].revealed = true
                explodedIndex = neighbor
                phase = .lost
                stopTimer()
                revealMines()
                onChange?()
                return
            }
            floodReveal(from: neighbor)
        }
        checkForWin()
        onChange?()
    }

    private func placeMines(excluding safeIndex: Int) {
        var candidates = Array(cells.indices)
        candidates.removeAll { $0 == safeIndex }
        for index in candidates.shuffled().prefix(mineCount) {
            cells[index].hasMine = true
        }

        for index in cells.indices {
            cells[index].adjacentMines = neighbors(of: index).reduce(0) {
                $0 + (cells[$1].hasMine ? 1 : 0)
            }
        }
        minesPlaced = true
    }

    private func floodReveal(from start: Int) {
        var queue = [start]
        var cursor = 0
        var visited = Set<Int>()

        while cursor < queue.count {
            let index = queue[cursor]
            cursor += 1
            guard !visited.contains(index) else { continue }
            visited.insert(index)
            guard !cells[index].hasMine, cells[index].mark != .flag else { continue }

            cells[index].revealed = true
            cells[index].mark = .none

            if cells[index].adjacentMines == 0 {
                for neighbor in neighbors(of: index)
                    where !cells[neighbor].revealed && cells[neighbor].mark != .flag {
                    queue.append(neighbor)
                }
            }
        }
    }

    private func revealMines() {
        for index in cells.indices where cells[index].hasMine {
            cells[index].revealed = true
        }
    }

    private func checkForWin() {
        let safeCellsAreOpen = cells.allSatisfy { $0.hasMine || $0.revealed }
        guard safeCellsAreOpen else { return }
        phase = .won
        stopTimer()
        for index in cells.indices where cells[index].hasMine {
            cells[index].mark = .flag
        }
        onWin?(difficulty, elapsedSeconds)
    }

    private func startTimer() {
        stopTimer()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.phase == .playing else { return }
                self.elapsedSeconds = min(999, self.elapsedSeconds + 1)
                self.onChange?()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
