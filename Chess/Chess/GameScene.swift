import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    var test = SKSpriteNode()
    let tileSize: CGFloat = 50.0
    var squarePath: CGRect {
        return CGRect(x: -tileSize / 2, y: -tileSize / 2, width: tileSize, height: tileSize)
    }
    
    var lastUpdateOfSelectedPiecesColor: SKColor? = .black
    
    // Create the board matrix as a 2D array of SKShapeNode
    var board: [[SKShapeNode]] = []
    var pieces: [[SKSpriteNode?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    var selectedPiece: SKSpriteNode? = SKSpriteNode()
    var isWhitesMove: Bool = true
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        
        // Initialize the board array
        for row in 0..<8 {
            var boardRow: [SKShapeNode] = []
            for col in 0..<8 {
                let squareNode = SKShapeNode(rect: squarePath)
                squareNode.fillColor = (row + col) % 2 == 0 ? SKColor.darkGray : SKColor.white
                boardRow.append(squareNode)
            }
            board.append(boardRow)
        }
        
        // Position and add the board squares to the scene
        renderBoard(center: CGPoint(x: 0, y: 0))
        
        // Add the pieces to the board
        addPieces()
    }
    
    func renderBoard(center: CGPoint) {
        let boardSize: CGFloat = tileSize * 8
        let halfBoardSize = boardSize / 2
        
        for (row, boardRow) in board.enumerated() {
            for (col, tile) in boardRow.enumerated() {
                let x = center.x - halfBoardSize + tileSize * CGFloat(col) + tileSize / 2
                let y = center.y - halfBoardSize + tileSize * CGFloat(row) + tileSize / 2
                tile.position = CGPoint(x: x, y: y)
                addChild(tile)
            }
        }
    }
    
    func addPieces() {
        // Define the initial setup of pieces
        let initialSetup: [(String, Int, Int)] = [
            // White pieces
            ("whitepawn", 1, 0), ("whitepawn", 1, 1), ("whitepawn", 1, 2), ("whitepawn", 1, 3),
            ("whitepawn", 1, 4), ("whitepawn", 1, 5), ("whitepawn", 1, 6), ("whitepawn", 1, 7),
            ("whiterook", 0, 0), ("whiterook", 0, 7),
            ("whiteknight", 0, 1), ("whiteknight", 0, 6),
            ("whitebishop", 0, 2), ("whitebishop", 0, 5),
            ("whitequeen", 0, 3),
            ("whiteking", 0, 4),
            
            // Black pieces
            ("blackpawn", 6, 0), ("blackpawn", 6, 1), ("blackpawn", 6, 2), ("blackpawn", 6, 3),
            ("blackpawn", 6, 4), ("blackpawn", 6, 5), ("blackpawn", 6, 6), ("blackpawn", 6, 7),
            ("blackrook", 7, 0), ("blackrook", 7, 7),
            ("blackknight", 7, 1), ("blackknight", 7, 6),
            ("blackbishop", 7, 2), ("blackbishop", 7, 5),
            ("blackqueen", 7, 3),
            ("blackking", 7, 4)
        ]
        
        for (imageName, row, col) in initialSetup {
            let piece = SKSpriteNode(imageNamed: imageName)
            piece.name = imageName
            // Calculate the position based on the tile's position
            piece.position = board[row][col].position
            pieces[row][col] = piece
            addChild(piece)
        }
    }
    
    func selectPiece(at location: (Int, Int)) {
        // Clear previous selection highlights
        for (rowIndex, row) in board.enumerated() {
            for (colIndex, tile) in row.enumerated() {
                if tile.fillColor != NSColor.red {
                    let defaultColor: SKColor = (rowIndex + colIndex) % 2 == 0 ? .darkGray : .white
                    tile.fillColor = defaultColor
                }
            }
        }
        
        // Select the piece at the given location
        if let selectedPiece = pieces[location.0][location.1] {
            
            self.selectedPiece = selectedPiece
            // Highlight the tile at the location
            board[location.0][location.1].fillColor = SKColor.green
        }
    }

    func evaluateMoves(checkForChecks: Bool = true, showCheckedChecks: Bool = true) -> [(Int, Int)] {
        guard let pieceName = selectedPiece?.name else { return [] }
        var moves: [(Int, Int)] = []

        // Find the position of the selectedPiece
        let position = pieces.enumerated().compactMap { rowIndex, row in
            row.enumerated().compactMap { colIndex, piece in
                piece == selectedPiece ? (rowIndex, colIndex) : nil
            }.first
        }.first ?? (0, 0)

        func wouldLeaveKingInCheck(move: (Int, Int)) -> Bool {
            var tempPieces = pieces.map { $0.map { $0 } }
            let originalPosition = position
            let targetPiece = tempPieces[move.0][move.1]
            tempPieces[move.0][move.1] = selectedPiece
            tempPieces[originalPosition.0][originalPosition.1] = nil

            let originalBoard = self.pieces
            self.pieces = tempPieces
            let isInCheck = isInCheck(selectedPiece?.name?.contains("white") == true ? "white" : "black", showChecks: showCheckedChecks)
            self.pieces = originalBoard

            return isInCheck
        }

        switch pieceName {
        case "whitepawn", "blackpawn":
            if pieceName.contains("white") {
                if position.0 < 7 && pieces[position.0 + 1][position.1] == nil {
                    moves.append((position.0 + 1, position.1))
                }
                if position.0 == 1 && pieces[position.0 + 2][position.1] == nil && pieces[position.0 + 1][position.1] == nil {
                    moves.append((position.0 + 2, position.1))
                }
                if position.0 < 7 && position.1 < 7 && pieces[position.0 + 1][position.1 + 1]?.name?.contains("black") == true {
                    moves.append((position.0 + 1, position.1 + 1))
                }
                if position.0 < 7 && position.1 > 0 && pieces[position.0 + 1][position.1 - 1]?.name?.contains("black") == true {
                    moves.append((position.0 + 1, position.1 - 1))
                }
            } else {
                if position.0 > 0 && pieces[position.0 - 1][position.1] == nil {
                    moves.append((position.0 - 1, position.1))
                }
                if position.0 == 6 && pieces[position.0 - 2][position.1] == nil && pieces[position.0 - 1][position.1] == nil {
                    moves.append((position.0 - 2, position.1))
                }
                if position.0 > 0 && position.1 < 7 && pieces[position.0 - 1][position.1 + 1]?.name?.contains("white") == true {
                    moves.append((position.0 - 1, position.1 + 1))
                }
                if position.0 > 0 && position.1 > 0 && pieces[position.0 - 1][position.1 - 1]?.name?.contains("white") == true {
                    moves.append((position.0 - 1, position.1 - 1))
                }
            }
        case "whiterook", "blackrook":
            let directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]
            for direction in directions {
                for i in 1..<8 {
                    let newPos = (position.0 + i * direction.0, position.1 + i * direction.1)
                    if newPos.0 >= 0 && newPos.0 < 8 && newPos.1 >= 0 && newPos.1 < 8 {
                        if pieces[newPos.0][newPos.1] == nil {
                            moves.append(newPos)
                        } else {
                            if pieces[newPos.0][newPos.1]?.name?.contains("black") == pieceName.contains("white") {
                                moves.append(newPos)
                            }
                            break
                        }
                    }
                }
            }
        case "whiteknight", "blackknight":
            let positions = [
                (position.0 + 2, position.1 + 1), (position.0 + 2, position.1 - 1),
                (position.0 - 2, position.1 + 1), (position.0 - 2, position.1 - 1),
                (position.0 + 1, position.1 + 2), (position.0 + 1, position.1 - 2),
                (position.0 - 1, position.1 + 2), (position.0 - 1, position.1 - 2)
            ]
            for pos in positions {
                if pos.0 >= 0 && pos.0 < 8 && pos.1 >= 0 && pos.1 < 8 {
                    if pieces[pos.0][pos.1] == nil || pieces[pos.0][pos.1]?.name?.contains("black") == pieceName.contains("white") {
                        moves.append(pos)
                    }
                }
            }
        case "whitebishop", "blackbishop":
            let directions = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
            for direction in directions {
                for i in 1..<8 {
                    let newPos = (position.0 + i * direction.0, position.1 + i * direction.1)
                    if newPos.0 >= 0 && newPos.0 < 8 && newPos.1 >= 0 && newPos.1 < 8 {
                        if pieces[newPos.0][newPos.1] == nil {
                            moves.append(newPos)
                        } else {
                            if pieces[newPos.0][newPos.1]?.name?.contains("black") == pieceName.contains("white") {
                                moves.append(newPos)
                            }
                            break
                        }
                    }
                }
            }
        case "whitequeen", "blackqueen":
            let directions = [
                (1, 0), (-1, 0), (0, 1), (0, -1),
                (1, 1), (1, -1), (-1, 1), (-1, -1)
            ]
            for direction in directions {
                for i in 1..<8 {
                    let newPos = (position.0 + i * direction.0, position.1 + i * direction.1)
                    if newPos.0 >= 0 && newPos.0 < 8 && newPos.1 >= 0 && newPos.1 < 8 {
                        if pieces[newPos.0][newPos.1] == nil {
                            moves.append(newPos)
                        } else {
                            if pieces[newPos.0][newPos.1]?.name?.contains("black") == pieceName.contains("white") {
                                moves.append(newPos)
                            }
                            break
                        }
                    }
                }
            }
        case "whiteking", "blackking":
            let positions = [
                (position.0 + 1, position.1), (position.0 - 1, position.1),
                (position.0, position.1 + 1), (position.0, position.1 - 1),
                (position.0 + 1, position.1 + 1), (position.0 + 1, position.1 - 1),
                (position.0 - 1, position.1 + 1), (position.0 - 1, position.1 - 1)
            ]
            for pos in positions {
                if pos.0 >= 0 && pos.0 < 8 && pos.1 >= 0 && pos.1 < 8 {
                    if pieces[pos.0][pos.1] == nil || pieces[pos.0][pos.1]?.name?.contains("black") == pieceName.contains("white") {
                        moves.append(pos)
                    }
                }
            }
        default:
            return []
        }

        // Filter out moves that would leave the king in check
        if checkForChecks == true { moves = moves.filter { !wouldLeaveKingInCheck(move: $0) } }

        return moves
    }

    func capturePiece(at position: (Int, Int)) {
        // Identify the piece to be captured
        if let capturedPiece = pieces[position.0][position.1] {
            // Remove the captured piece from the board
            capturedPiece.removeFromParent()
            
            // Remove the captured piece from the pieces array
            pieces[position.0][position.1] = nil
        }
    }
    
    func moveSelectedPiece(to newPosition: (Int, Int)) {
        guard let pieceToMove = selectedPiece else { return }

        // Calculate the target position on the board
        let targetPosition = board[newPosition.0][newPosition.1].position

        // Check if there is a piece to capture at the new position
        if pieces[newPosition.0][newPosition.1] != nil {
            // Capture the piece
            capturePiece(at: newPosition)
        }

        // Create the move action
        let moveAction = SKAction.move(to: targetPosition, duration: 0.3)

        // Run the move action
        pieceToMove.run(moveAction) {
            // Update the pieces array
            let currentPiecePosition = self.pieces.enumerated().compactMap { rowIndex, row in
                row.enumerated().compactMap { colIndex, piece in
                    piece == pieceToMove ? (rowIndex, colIndex) : nil
                }.first
            }.first ?? (0, 0)

            self.pieces[currentPiecePosition.0][currentPiecePosition.1] = nil
            self.pieces[newPosition.0][newPosition.1] = pieceToMove

            // Reset the previous selected square color
            self.deselectSquare()

            // Handle pawn promotion
            if pieceToMove.name == "whitepawn" && newPosition.0 == 7 {
                pieceToMove.texture = SKTexture(imageNamed: "whitequeen")
                pieceToMove.name = "whitequeen"
            } else if pieceToMove.name == "blackpawn" && newPosition.0 == 0 {
                pieceToMove.texture = SKTexture(imageNamed: "blackqueen")
                pieceToMove.name = "blackqueen"
            }

            // Use pieceToMove instead of selectedPiece
            self.isInCheck((pieceToMove.name?.hasPrefix("white")) ?? false ? "black" : "white")
            
            // Reset selectedPiece
            self.selectedPiece = nil
        }
    }

    func isInCheck(_ side: String, showChecks: Bool = true) -> Bool {
        guard side == "black" || side == "white" else { return false }
        print("side is valid! side = \(side)\n")
        
        // Find the king's position
        var kingPosition: CGPoint? = nil
        var kingBoardPosition: (Int, Int) = (0, 0)
        for piece in pieces {
            for piece_ in piece {
                if piece_?.name == "\(side)king" {
                    kingPosition = piece_?.position
                    print("kingPosition set to: \(kingPosition)\n")
                    for (rowIndex, row) in board.enumerated() {
                        for (colIndex, tile) in row.enumerated() {
                            if tile.position == kingPosition {
                                kingBoardPosition = (rowIndex, colIndex)
                                print("kingBoardPosition set to: \(kingBoardPosition)\n")
                            }
                        }
                    }
                    break
                }
            }
        }

        guard let kingPos = kingPosition else { return false }
        print("kingPosition is valid!\n")

        let originalPiece = selectedPiece
        
        // Check if any opponent's piece can move to the king's position
        for piece in pieces {
            for piece_ in piece where piece_?.name?.hasPrefix(side) == false {
                self.selectedPiece = piece_
                
                let moves = evaluateMoves(checkForChecks: false)
                for move in moves {
                    if board[move.0][move.1].contains(kingPos) {
                        print("isInCheck returns true!")
                        return true
                    }
                }
            }
        }

        selectedPiece = originalPiece
        if selectedPiece?.name != "\(side)king" {
            let defaultColor: SKColor = (kingBoardPosition.0 + kingBoardPosition.1) % 2 == 0 ? .darkGray : .white
            board[kingBoardPosition.0][kingBoardPosition.1].fillColor = defaultColor
        }
        print("isInCheck returns false!")
        return false
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let boardRow = Int((location.y + tileSize * 4) / tileSize)
        let boardCol = Int((location.x + tileSize * 4) / tileSize)

        // Deselect the previously selected square
        deselectSquare()

        if let piece = selectedPiece {
            // Evaluate the valid moves for the selected piece
            let validMoves = evaluateMoves(showCheckedChecks: false)

            // Check if the touch location is one of the valid moves
            if validMoves.contains(where: { $0 == (boardRow, boardCol) }) {
                // Move the selected piece
                moveSelectedPiece(to: (boardRow, boardCol))

                // Toggle the turn
                isWhitesMove.toggle()
                selectedPiece = nil // Ensure the piece is deselected after the move
                return
            } else {
                // Deselect the piece if the move is invalid
                selectedPiece = nil
            }
        }

        guard boardCol >= 0 && boardCol <= 7 && boardRow >= 0 && boardRow <= 7 else { return }
        
        // Select the piece at the touch location
        if let piece = pieces[boardRow][boardCol] {
            // Check if the piece belongs to the correct side
            if (isWhitesMove && piece.name?.contains("white") == true) || (!isWhitesMove && piece.name?.contains("black") == true) {
                self.selectPiece(at: (boardRow, boardCol))
            } else {
                // No piece is selected, ensure selectedPiece is nil
                selectedPiece = nil
            }
        } else {
            // No piece is selected, ensure selectedPiece is nil
            selectedPiece = nil
        }
    }

    func deselectSquare() {
        if let selectedPiece = selectedPiece {
            if let previousSelectedPosition = pieces.enumerated().compactMap({ rowIndex, row in
                row.enumerated().compactMap { colIndex, piece in
                    piece == selectedPiece ? (rowIndex, colIndex) : nil
                }.first
            }).first {
                let defaultColor: SKColor = (previousSelectedPosition.0 + previousSelectedPosition.1) % 2 == 0 ? .darkGray : .white
                board[previousSelectedPosition.0][previousSelectedPosition.1].fillColor = defaultColor
                if pieces[previousSelectedPosition.0][previousSelectedPosition.1]!.name?.hasSuffix("king") == true {
                    let kingIsInCheck = isInCheck(String(pieces[previousSelectedPosition.0][previousSelectedPosition.1]!.name!.prefix(5)))
                    if kingIsInCheck {
                        board[previousSelectedPosition.0][previousSelectedPosition.1].fillColor = .red
                    }
                }
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let location = event.location(in: self)
        // Handle mouse dragged event
    }
    
    override func mouseUp(with event: NSEvent) {
        let location = event.location(in: self)
        // Handle mouse up event
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle key down event
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        var kingPosition: CGPoint? = nil
        var kingBoardPosition: (Int, Int) = (0, 0)
        for piece in pieces {
            for piece_ in piece {
                if piece_?.name == "blackking" {
                    kingPosition = piece_?.position
                    for (rowIndex, row) in board.enumerated() {
                        for (colIndex, tile) in row.enumerated() {
                            if tile.position == kingPosition {
                                kingBoardPosition = (rowIndex, colIndex)
                            }
                        }
                    }
                    break
                }
            }
        }
        
        if isInCheck("black", showChecks: false) && board[kingBoardPosition.0][kingBoardPosition.1].fillColor != lastUpdateOfSelectedPiecesColor {
            lastUpdateOfSelectedPiecesColor = board[kingBoardPosition.0][kingBoardPosition.1].fillColor
            print("blackking's square color changed to: \(lastUpdateOfSelectedPiecesColor ?? .orange)")
        }
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
