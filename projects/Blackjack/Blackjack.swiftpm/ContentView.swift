import SwiftUI

// MARK: - Card Logic
enum Suit: String, CaseIterable {
    case spades = "♠︎", hearts = "♥︎", diamonds = "♦︎", clubs = "♣︎"
}

enum Rank: String, CaseIterable {
    case two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9", ten = "10", jack = "J", queen = "Q", king = "K", ace = "A"
    
    var value: Int {
        switch self {
        case .jack, .queen, .king: return 10
        case .ace: return 11
        default: return Int(self.rawValue) ?? 0
        }
    }
}

struct Card {
    let suit: Suit
    let rank: Rank
    
    func ascii() -> String {
        let rankString = rank.rawValue.padding(toLength: 2, withPad: " ", startingAt: 0)
        let suitString = suit.rawValue
        
        let lines = [
            "┌───────┐",
            "│\(rankString)     │",
            "│       │",
            "│   \(suitString)   │",
            "│       │",
            "│     \(rankString)│",
            "└───────┘"
        ]
        return lines.joined(separator: "\n")
    }
    
    static func back() -> String {
        let lines = [
            "┌───────┐",
            "│░░░░░░░│",
            "│░░░░░░░│",
            "│░░░░░░░│",
            "│░░░░░░░│",
            "│░░░░░░░│",
            "└───────┘"
        ]
        return lines.joined(separator: "\n")
    }
}

// Player and game logic
class Player: ObservableObject {
    @Published var hand: [Card] = []
    
    func takeCard(_ card: Card) {
        hand.append(card)
    }
    
    func clearHand() {
        hand = []
    }
    
    var score: Int {
        var total = hand.reduce(0) { $0 + $1.rank.value }
            var aceCount = hand.filter { $0.rank == .ace }.count
        
        while total > 21 && aceCount > 0 {
            total -= 10
            aceCount -= 1
        }
        
        return total
    }
}

class Game: ObservableObject {
    @Published var deck: [Card] = []
    @Published var player = Player()
    @Published var dealer = Player()
    @Published var message: String = ""
    @Published var gameIsOver: Bool = true
    @Published var playerBalance: Int = 100 // Starting balance
    @Published var currentBet: Int = 10 // Default bet
    @Published var betPlaced: Bool = false
    
    init() {
        newDeck()
    }
    
    func newDeck() {
        deck = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        deck.shuffle()
    }
    
    func placeBet() {
        guard playerBalance >= currentBet else {
            message = "Not enough balance to place this bet."
            return
        }
        playerBalance -= currentBet
        betPlaced = true
        deal()
    }
    
    func deal() {
        newDeck() // Start with a new deck every game for simplicity
        
        player.clearHand()
        dealer.clearHand()
        
        guard deck.count >= 4 else {
            message = "Not enough cards. Shuffling a new deck."
            return
        }
        player.takeCard(deck.removeFirst())
        dealer.takeCard(deck.removeFirst())
        player.takeCard(deck.removeFirst())
        dealer.takeCard(deck.removeFirst())
        
        message = "Your score: \(player.score)"
        gameIsOver = false
        
        if player.score == 21 {
            endGame(message: "Blackjack! You win!")
        }
    }
    
    func hit() {
        guard !gameIsOver else { return }
        
        guard deck.count >= 1 else {
            message = "Not enough cards."
            endGame(message: "Game Over")
            return
        }
        player.takeCard(deck.removeFirst())
        
        if player.score > 21 {
            endGame(message: "You bust! You lose.")
        } else {
            message = "Your score: \(player.score)"
        }
    }
    
    func stand() {
        guard !gameIsOver else { return }
        
        message = "Dealer's turn..."
        
        while dealer.score < 17 {
            guard deck.count >= 1 else {
                endGame(message: "Not enough cards. Game Over")
                return
            }
            dealer.takeCard(deck.removeFirst())
        }
        
        if dealer.score > 21 {
            endGame(message: "Dealer busts! You win!")
        } else if player.score > dealer.score {
            endGame(message: "You win!")
        } else if player.score < dealer.score {
            endGame(message: "Dealer wins!")
        } else {
            endGame(message: "It's a push!")
        }
    }
    
    private func endGame(message: String) {
        self.message = message
        gameIsOver = true
        betPlaced = false
        
        // Payout logic
        if message.contains("You win!") {
            playerBalance += currentBet * 2
        } else if message.contains("push!") {
            playerBalance += currentBet
        }
    }
    
    func joinCardStrings(_ cards: [Card], revealFirst: Bool = true) -> String {
        let lines = cards.indices.map { index in
            if index == 0 && !revealFirst {
                return Card.back()
            } else {
                return cards[index].ascii()
            }
        }.map { $0.components(separatedBy: "\n") }
        
        guard let first = lines.first else { return "" }
        
        var resultLines = first
        for i in 1..<lines.count {
            for j in 0..<resultLines.count {
                resultLines[j] += " " + lines[i][j]
            }
        }
        return resultLines.joined(separator: "\n")
    }
}

// SwiftUI View
struct ContentView: View {
    @StateObject var game = Game()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Blackjack")
                .font(.largeTitle)
            
            // Player Balance
            Text("Balance: $\(game.playerBalance)")
                .font(.title3)
                .fontWeight(.bold)
            
            // Dealer's Hand Display
            VStack {
                Text("Dealer's Hand:")
                    .font(.headline)
                Text(game.joinCardStrings(game.dealer.hand, revealFirst: game.gameIsOver))
                    .font(.monospaced(.body)())
                    .textSelection(.disabled)
            }
            .frame(height: 150)
            
            Spacer()
            
            // Game Message
            Text(game.message)
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Player's Hand Display
            VStack {
                Text("Your Hand:")
                    .font(.headline)
                Text(game.joinCardStrings(game.player.hand))
                    .font(.monospaced(.body)())
                    .textSelection(.disabled)
            }
            .frame(height: 150)
            
            // Control Buttons
            if game.betPlaced {
                HStack(spacing: 20) {
                    Button("Hit") {
                        game.hit()
                    }
                    .padding()
                    .background(game.gameIsOver ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(game.gameIsOver)
                    
                    Button("Stand") {
                        game.stand()
                    }
                    .padding()
                    .background(game.gameIsOver ? Color.gray : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(game.gameIsOver)
                }
            } else {
                HStack(spacing: 15) {
                    Text("Bet: ")
                    
                    Button("-100") {
                        if game.currentBet > 100 {
                            game.currentBet -= 100
                            
                        }
                    }
                    .disabled(game.betPlaced)
                    
                    Button("-") {
                        if game.currentBet > 10 {
                            game.currentBet -= 10
                        }
                    }
                    .disabled(game.betPlaced)
                    
                    Text("$\(game.currentBet)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button("+") {
                        if game.playerBalance >= game.currentBet + 10 {
                            game.currentBet += 10
                        }
                    }
                    .disabled(game.betPlaced)
                    Button("+100") {
                        if game.playerBalance >= game.currentBet + 100 {
                            game.currentBet += 100
                        }
                    }
                    .disabled(game.betPlaced)
                    
                    Button("Place Bet") {
                        game.placeBet()
                    }
                    .disabled(game.playerBalance < game.currentBet)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

