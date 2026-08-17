//
//  MatchModels.swift
//  ScoreWatch
//
//  Osnovni podatkovni tipi: igralec, šport, način štetja, nastavitve dvoboja
//  in stanje dvoboja. Stanje je namerno "value type" (struct), ker to omogoča
//  preprost in zanesljiv undo prek sklada posnetkov stanja.
//

import Foundation

// MARK: - Igralec

enum Player: Int, Codable, CaseIterable {
    case me = 0        // jaz (zgornja polovica zaslona)
    case opponent = 1  // nasprotnik (spodnja polovica zaslona)

    var other: Player { self == .me ? .opponent : .me }

    var shortName: String {
        switch self {
        case .me: return "JAZ"
        case .opponent: return "NAS"
        }
    }
}

// MARK: - Šport

enum Sport: String, Codable, CaseIterable, Identifiable {
    case tennis
    case badminton

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tennis: return "Tenis"
        case .badminton: return "Badminton"
        }
    }

    var symbol: String {
        switch self {
        case .tennis: return "figure.tennis"
        case .badminton: return "figure.badminton"
        }
    }
}

// MARK: - Način štetja

enum ScoringMode: String, Codable, CaseIterable, Identifiable {
    case official   // uradna pravila (gemi, seti, tie-break oz. do 21)
    case free       // prosto štetje – samo dva števca

    var id: String { rawValue }

    var title: String {
        switch self {
        case .official: return "Uradna pravila"
        case .free: return "Prosto štetje"
        }
    }
}

// MARK: - Nastavitve dvoboja

struct MatchSettings: Codable, Equatable {
    var sport: Sport = .tennis
    var mode: ScoringMode = .official

    /// Število setov, ki se igrajo (1, 3 ali 5). Zmagovalec potrebuje polovico + 1.
    var setsToPlay: Int = 3

    /// Tenis: brez prednosti – pri 40:40 odloči naslednja točka.
    var noAd: Bool = false

    /// Tenis: namesto odločilnega seta se igra podaljšana igra do 10 točk.
    var matchTiebreak: Bool = false

    /// Kdo servira prvi.
    var firstServer: Player = .me

    /// Število setov, potrebnih za zmago.
    var setsNeeded: Int { setsToPlay / 2 + 1 }

    /// Tenis: tie-break pri 6:6.
    var tiebreakEnabled: Bool { true }
}

// MARK: - Rezultat enega seta

struct SetScore: Codable, Equatable, Hashable {
    var me: Int
    var opponent: Int

    /// Rezultat morebitne podaljšane igre (npr. 7:6 (5)).
    var tiebreakMe: Int? = nil
    var tiebreakOpponent: Int? = nil

    var display: String { "\(me):\(opponent)" }
}

// MARK: - Stanje dvoboja

struct MatchState: Codable, Equatable {

    // Točke v trenutni igri (tenis) oziroma v trenutnem setu (badminton, prosto štetje)
    var pointsMe: Int = 0
    var pointsOpponent: Int = 0

    // Gemi v trenutnem setu (samo tenis)
    var gamesMe: Int = 0
    var gamesOpponent: Int = 0

    // Osvojeni seti
    var setsMe: Int = 0
    var setsOpponent: Int = 0

    var completedSets: [SetScore] = []

    // Podaljšana igra (tie-break)
    var inTiebreak: Bool = false
    var isMatchTiebreak: Bool = false
    var tiebreakFirstServer: Player = .me

    var server: Player = .me

    var isFinished: Bool = false
    var winner: Player? = nil

    /// Skupno število odigranih točk – uporabno za statistiko.
    var totalPoints: Int = 0

    /// Zaporedje osvojenih točk (za niz zaporednih točk).
    var lastScorer: Player? = nil
    var streak: Int = 0
}
