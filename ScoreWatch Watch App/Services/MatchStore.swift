//
//  MatchStore.swift
//  ScoreWatch
//
//  Shramba odigranih dvobojev (zadnjih 50) v UserDefaults.
//

import Foundation

struct MatchRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var sport: Sport
    var mode: ScoringMode
    var scoreLine: String        // npr. "6:4  3:6  7:6"
    var setsMe: Int
    var setsOpponent: Int
    var winnerIsMe: Bool
    var duration: TimeInterval
    var totalPoints: Int
    var averageHeartRate: Double?

    var durationText: String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        return hours > 0 ? "\(hours) h \(minutes % 60) min" : "\(minutes) min"
    }

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.dateFormat = "d. M. yyyy"
        return formatter.string(from: date)
    }
}

final class MatchStore: ObservableObject {

    private static let key = "scorewatch.matches.v1"

    @Published private(set) var matches: [MatchRecord] = []

    init() { load() }

    func add(_ record: MatchRecord) {
        matches.insert(record, at: 0)
        if matches.count > 50 { matches = Array(matches.prefix(50)) }
        save()
    }

    func deleteAll() {
        matches = []
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([MatchRecord].self, from: data)
        else { return }
        matches = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(matches) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    // MARK: - Statistika

    var winRate: Double {
        guard !matches.isEmpty else { return 0 }
        let wins = matches.filter(\.winnerIsMe).count
        return Double(wins) / Double(matches.count)
    }
}
