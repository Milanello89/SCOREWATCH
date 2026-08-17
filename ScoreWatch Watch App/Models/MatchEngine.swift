//
//  MatchEngine.swift
//  ScoreWatch
//
//  Celotna logika štetja za tenis in badminton.
//
//  Zasnova: stanje dvoboja je struct (MatchState). Pred vsako spremembo se
//  trenutno stanje shrani v sklad `history`. Undo je zato zgolj "pop" s sklada
//  in vedno vrne popolnoma pravilno prejšnje stanje – tudi če je zadnja točka
//  zaključila gem, set ali celoten dvoboj.
//

import Foundation
import SwiftUI

// MARK: - Dogodek, ki ga vrne štetje (za haptiko in prikaz)

enum ScoreEvent: Equatable {
    case point          // navadna točka
    case gameWon        // osvojen gem (tenis)
    case setWon         // osvojen set
    case matchWon       // osvojen dvoboj
    case undo           // razveljavitev
    case ignored        // dvoboj je končan, klik nima učinka
}

final class MatchEngine: ObservableObject {

    @Published private(set) var state = MatchState()
    @Published private(set) var settings = MatchSettings()
    @Published private(set) var lastEvent: ScoreEvent = .point

    /// Sklad prejšnjih stanj – osnova za undo.
    private var history: [MatchState] = []

    private(set) var startDate: Date = Date()
    private(set) var endDate: Date?

    var canUndo: Bool { !history.isEmpty }

    var elapsed: TimeInterval {
        (endDate ?? Date()).timeIntervalSince(startDate)
    }

    // MARK: - Začetek dvoboja

    func start(with settings: MatchSettings) {
        self.settings = settings
        var s = MatchState()
        s.server = settings.firstServer
        s.tiebreakFirstServer = settings.firstServer

        // Če se igra samo en set in je vklopljena podaljšana igra namesto seta,
        // se ta začne takoj.
        if settings.sport == .tennis,
           settings.mode == .official,
           settings.matchTiebreak,
           settings.setsToPlay == 1 {
            s.inTiebreak = true
            s.isMatchTiebreak = true
        }

        self.state = s
        self.history = []
        self.startDate = Date()
        self.endDate = nil
        self.lastEvent = .point
    }

    // MARK: - Dodelitev točke

    @discardableResult
    func award(_ player: Player) -> ScoreEvent {
        guard !state.isFinished else {
            lastEvent = .ignored
            return .ignored
        }

        history.append(state)
        if history.count > 500 { history.removeFirst() }

        var s = state
        s.totalPoints += 1

        if s.lastScorer == player {
            s.streak += 1
        } else {
            s.lastScorer = player
            s.streak = 1
        }

        var event: ScoreEvent = .point

        switch (settings.mode, settings.sport) {
        case (.free, _):
            addPoint(to: player, in: &s)
            s.server = player   // v prostem štetju servira zadnji dobitnik točke

        case (.official, .badminton):
            addPoint(to: player, in: &s)
            s.server = player   // badminton: servira zmagovalec zadnje izmenjave
            event = resolveBadmintonSet(&s)

        case (.official, .tennis):
            addPoint(to: player, in: &s)
            event = resolveTennisPoint(&s)
        }

        state = s
        if s.isFinished, endDate == nil { endDate = Date() }
        lastEvent = event
        return event
    }

    // MARK: - Undo

    @discardableResult
    func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        state = previous
        endDate = nil
        lastEvent = .undo
        return true
    }

    // MARK: - Pomožno

    private func addPoint(to player: Player, in s: inout MatchState) {
        if player == .me { s.pointsMe += 1 } else { s.pointsOpponent += 1 }
    }

    // MARK: - Badminton

    /// Set do 21 točk, potrebna razlika 2, absolutna zgornja meja 30
    /// (pri 29:29 odloči 30. točka).
    private func resolveBadmintonSet(_ s: inout MatchState) -> ScoreEvent {
        let a = s.pointsMe, b = s.pointsOpponent
        let leader: Player = a > b ? .me : .opponent
        let hi = max(a, b), diff = abs(a - b)

        guard (hi >= 21 && diff >= 2) || hi >= 30 else { return .point }

        s.completedSets.append(SetScore(me: a, opponent: b))
        if leader == .me { s.setsMe += 1 } else { s.setsOpponent += 1 }
        s.pointsMe = 0
        s.pointsOpponent = 0

        if s.setsMe >= settings.setsNeeded || s.setsOpponent >= settings.setsNeeded {
            s.isFinished = true
            s.winner = leader
            return .matchWon
        }

        // Nov set začne servirati zmagovalec prejšnjega seta.
        s.server = leader
        return .setWon
    }

    // MARK: - Tenis

    private func resolveTennisPoint(_ s: inout MatchState) -> ScoreEvent {
        if s.inTiebreak {
            return resolveTiebreak(&s)
        }

        let a = s.pointsMe, b = s.pointsOpponent
        let leader: Player = a > b ? .me : .opponent
        let hi = max(a, b), diff = abs(a - b)

        let gameWon: Bool
        if settings.noAd {
            // Brez prednosti: pri 40:40 (3:3) odloči naslednja točka.
            gameWon = hi >= 4 && diff >= 1
        } else {
            gameWon = hi >= 4 && diff >= 2
        }

        guard gameWon else { return .point }

        s.pointsMe = 0
        s.pointsOpponent = 0
        if leader == .me { s.gamesMe += 1 } else { s.gamesOpponent += 1 }
        s.server = s.server.other   // servis se menja po vsakem gemu

        return resolveTennisSet(&s, gameWinner: leader)
    }

    private func resolveTiebreak(_ s: inout MatchState) -> ScoreEvent {
        let target = s.isMatchTiebreak ? 10 : 7
        let a = s.pointsMe, b = s.pointsOpponent
        let leader: Player = a > b ? .me : .opponent
        let hi = max(a, b), diff = abs(a - b)

        // Servis v podaljšani igri: prvo točko servira izbrani igralec,
        // nato se servis menja na vsaki dve točki.
        let played = a + b
        let shifts = (played + 1) / 2
        s.server = (shifts % 2 == 0) ? s.tiebreakFirstServer : s.tiebreakFirstServer.other

        guard hi >= target && diff >= 2 else { return .point }

        if s.isMatchTiebreak {
            // Podaljšana igra namesto odločilnega seta – konča dvoboj.
            s.completedSets.append(SetScore(me: a, opponent: b))
            if leader == .me { s.setsMe += 1 } else { s.setsOpponent += 1 }
            s.pointsMe = 0
            s.pointsOpponent = 0
            s.inTiebreak = false
            s.isFinished = true
            s.winner = leader
            return .matchWon
        }

        // Običajen tie-break: set se konča z 7:6.
        if leader == .me { s.gamesMe += 1 } else { s.gamesOpponent += 1 }
        let set = SetScore(me: s.gamesMe,
                           opponent: s.gamesOpponent,
                           tiebreakMe: a,
                           tiebreakOpponent: b)
        s.pointsMe = 0
        s.pointsOpponent = 0
        s.inTiebreak = false

        return closeSet(&s, set: set, winner: leader)
    }

    private func resolveTennisSet(_ s: inout MatchState, gameWinner: Player) -> ScoreEvent {
        let g1 = s.gamesMe, g2 = s.gamesOpponent
        let hi = max(g1, g2), diff = abs(g1 - g2)

        // Set osvojen: 6:0 – 6:4 ali 7:5
        if hi >= 6 && diff >= 2 {
            let set = SetScore(me: g1, opponent: g2)
            return closeSet(&s, set: set, winner: gameWinner)
        }

        // 6:6 – začne se podaljšana igra
        if settings.tiebreakEnabled && g1 == 6 && g2 == 6 {
            s.inTiebreak = true
            s.isMatchTiebreak = false
            s.tiebreakFirstServer = s.server  // servira tisti, ki bi serviral naslednji gem
        }

        return .gameWon
    }

    private func closeSet(_ s: inout MatchState, set: SetScore, winner: Player) -> ScoreEvent {
        s.completedSets.append(set)
        if winner == .me { s.setsMe += 1 } else { s.setsOpponent += 1 }
        s.gamesMe = 0
        s.gamesOpponent = 0

        if s.setsMe >= settings.setsNeeded || s.setsOpponent >= settings.setsNeeded {
            s.isFinished = true
            s.winner = winner
            return .matchWon
        }

        // Ali se odločilni set igra kot podaljšana igra do 10?
        if settings.matchTiebreak,
           s.setsMe == settings.setsNeeded - 1,
           s.setsOpponent == settings.setsNeeded - 1 {
            s.inTiebreak = true
            s.isMatchTiebreak = true
            s.tiebreakFirstServer = s.server
        }

        return .setWon
    }

    // MARK: - Prikaz rezultata

    /// Glavna številka za posameznega igralca (velik prikaz na zaslonu).
    func displayPoints(for player: Player) -> String {
        let a = state.pointsMe, b = state.pointsOpponent
        let mine = player == .me ? a : b
        let theirs = player == .me ? b : a

        // Badminton, prosto štetje in podaljšana igra: navadne številke.
        guard settings.mode == .official, settings.sport == .tennis, !state.inTiebreak else {
            return "\(mine)"
        }

        // Tenis: 0 / 15 / 30 / 40 / prednost
        if mine >= 3 && theirs >= 3 {
            if mine == theirs { return "40" }
            if mine > theirs { return settings.noAd ? "40" : "AD" }
            return "40"
        }

        switch mine {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        default: return "40"
        }
    }

    /// Kratek opis stanja (npr. "Podaljšana igra", "Neodločeno", "Set žogica").
    var situationLabel: String? {
        guard settings.mode == .official, !state.isFinished else { return nil }

        if state.inTiebreak {
            return state.isMatchTiebreak ? "Podaljšana igra do 10" : "Podaljšana igra"
        }

        if settings.sport == .tennis,
           state.pointsMe >= 3, state.pointsOpponent >= 3,
           state.pointsMe == state.pointsOpponent {
            return settings.noAd ? "Odločilna točka" : "Neodločeno"
        }

        if let bp = ballPointLabel() { return bp }
        return nil
    }

    /// Zazna žogico za set oziroma za dvoboj.
    private func ballPointLabel() -> String? {
        // Simulacija: če bi naslednja točka končala set ali dvoboj.
        for p in Player.allCases {
            var probe = state
            addPoint(to: p, in: &probe)

            var copy = probe
            let event: ScoreEvent
            switch (settings.mode, settings.sport) {
            case (.official, .badminton): event = resolveBadmintonSet(&copy)
            case (.official, .tennis):    event = resolveTennisPoint(&copy)
            default:                      event = .point
            }

            if event == .matchWon {
                return p == .me ? "Žogica za dvoboj" : "Nasprotnik: žogica za dvoboj"
            }
            if event == .setWon {
                return p == .me ? "Žogica za set" : "Nasprotnik: žogica za set"
            }
        }
        return nil
    }

    /// Povzetek setov za glavo zaslona, npr. "6:4  3:6  2:1".
    var setSummary: String {
        var parts = state.completedSets.map { $0.display }
        if settings.mode == .official, settings.sport == .tennis, !state.isFinished {
            parts.append("\(state.gamesMe):\(state.gamesOpponent)")
        }
        return parts.joined(separator: "  ")
    }

    var finalScoreLine: String {
        state.completedSets.map { $0.display }.joined(separator: "  ")
    }
}
