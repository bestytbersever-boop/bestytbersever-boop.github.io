import SwiftUI

// MARK: - Game Models

enum CellState {
    case hidden
    case revealed
    case flagged
}

struct Cell: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    var isMine: Bool = false
    var neighborMines: Int = 0
    var state: CellState = .hidden
}

class MinesweeperBoard: ObservableObject {
    @Published var grid: [[Cell]] = []
    @Published var isGameOver = false
    @Published var isGameWon = false
    @Published var isFlagMode = false
    @Published var remainingMines = 0
    
    let rows: Int
    let cols: Int
    let totalMines: Int
    private var isFirstTap = true
    
    init(rows: Int = 10, cols: Int = 10, mines: Int = 12) {
        self.rows = rows
        self.cols = cols
        self.totalMines = mines
        resetGame()
    }
    
    func resetGame() {
        isGameOver = false
        isGameWon = false
        isFirstTap = true
        remainingMines = totalMines
        
        grid = (0..<rows).map { r in
            (0..<cols).map { c in
                Cell(row: r, col: c)
            }
        }
    }
    
    private func setupBoard(safeguarding row: Int, col: Int) {
        var minesPlaced = 0
        
        while minesPlaced < totalMines {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
            
            if (r == row && c == col) || grid[r][c].isMine {
                continue
            }
            
            grid[r][c].isMine = true
            minesPlaced += 1
        }
        
        for r in 0..<rows {
            for c in 0..<cols {
                if !grid[r][c].isMine {
                    grid[r][c].neighborMines = countNeighbors(r: r, c: c)
                }
            }
        }
    }
    
    private func countNeighbors(r: Int, c: Int) -> Int {
        var count = 0
        for dr in -1...1 {
            for dc in -1...1 {
                let nr = r + dr
                let nc = c + dc
                if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                    if grid[nr][nc].isMine { count += 1 }
                }
            }
        }
        return count
    }
    
    func handleTap(row: Int, col: Int) {
        guard !isGameOver && !isGameWon else { return }
        
        if isFirstTap {
            setupBoard(safeguarding: row, col: col)
            isFirstTap = false
        }
        
        if isFlagMode {
            toggleFlag(row: row, col: col)
            return
        }
        
        let cell = grid[row][col]
        guard cell.state == .hidden else { return }
        
        if cell.isMine {
            revealAllMines()
            isGameOver = true
            return
        }
        
        revealCell(row: row, col: col)
        checkWinCondition()
    }
    
    private func revealCell(row: Int, col: Int) {
        guard row >= 0 && row < rows && col >= 0 && col < cols else { return }
        guard grid[row][col].state == .hidden else { return }
        
        grid[row][col].state = .revealed
        
        if grid[row][col].neighborMines == 0 && !grid[row][col].isMine {
            for dr in -1...1 {
                for dc in -1...1 {
                    revealCell(row: row + dr, col: col + dc)
                }
            }
        }
    }
    
    func toggleFlag(row: Int, col: Int) {
        guard grid[row][col].state != .revealed else { return }
        
        if grid[row][col].state == .flagged {
            grid[row][col].state = .hidden
            remainingMines += 1
        } else {
            grid[row][col].state = .flagged
            remainingMines -= 1
        }
    }
    
    private func revealAllMines() {
        for r in 0..<rows {
            for c in 0..<cols {
                if grid[r][c].isMine {
                    grid[r][c].state = .revealed
                }
            }
        }
    }
    
    private func checkWinCondition() {
        for r in 0..<rows {
            for c in 0..<cols {
                let cell = grid[r][c]
                if !cell.isMine && cell.state != .revealed {
                    return
                }
            }
        }
        isGameWon = true
    }
}

// MARK: - UI Views

struct MinesweeperView: View {
    @StateObject private var board = MinesweeperBoard(rows: 10, cols: 10, mines: 12)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Status indicator
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(board.isGameOver ? .red : (board.isGameWon ? .green : .secondary))
                    .padding(.top, 8)
                
                Spacer()
                
                // Pure Grid Layout
                GeometryReader { geometry in
                    let minDimension = min(geometry.size.width, geometry.size.height)
                    let spacing: CGFloat = 2
                    let cellSize = (minDimension - (spacing * CGFloat(board.cols - 1))) / CGFloat(board.cols)
                    
                    VStack(spacing: spacing) {
                        ForEach(0..<board.rows, id: \.self) { r in
                            HStack(spacing: spacing) {
                                ForEach(0..<board.cols, id: \.self) { c in
                                    CellView(cell: board.grid[r][c])
                                        .frame(width: cellSize, height: cellSize)
                                        .onTapGesture {
                                            board.handleTap(row: r, col: c)
                                        }
                                        .onLongPressGesture(minimumDuration: 0.25) {
                                            board.toggleFlag(row: r, col: c)
                                        }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Minimal Action Bar
                HStack {
                    Button(action: { board.isFlagMode.toggle() }) {
                        Label(board.isFlagMode ? "Flag Mode" : "Dig Mode", 
                              systemImage: board.isFlagMode ? "flag.fill" : "hand.tap.fill")
                        .font(.body)
                        .foregroundColor(board.isFlagMode ? .orange : .accentColor)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Minesweeper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("💣 \(board.remainingMines)")
                        .font(.headline)
                        .fontDesign(.monospaced)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: board.resetGame) {
                        Image(systemName: board.isGameOver ? "face.dashed" : (board.isGameWon ? "face.smiling" : "arrow.clockwise"))
                    }
                }
            }
        }
    }
    
    private var statusMessage: String {
        if board.isGameOver { return "Game Over" }
        if board.isGameWon { return "Tournament Cleared!" }
        return board.isFlagMode ? "Tap to drop flags" : "Tap to clear spaces"
    }
}

struct CellView: View {
    let cell: Cell
    
    var body: some View {
        ZStack {
            switch cell.state {
            case .hidden:
                Color(.systemGray4)
            case .flagged:
                ZStack {
                    Color(.systemGray4)
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                }
            case .revealed:
                Color(.systemGray6)
                
                if cell.isMine {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                } else if cell.neighborMines > 0 {
                    Text("\(cell.neighborMines)")
                    // FIXED: Changed design: \.rounded to design: .rounded
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(colorForNumber(cell.neighborMines))
                }
            }
        }
    }
    
    private func colorForNumber(_ num: Int) -> Color {
        switch num {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return .indigo
        default: return .secondary
        }
    }
}
    
    private func colorForNumber(_ num: Int) -> Color {
        switch num {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return .indigo
        default: return .secondary
        }
    }

