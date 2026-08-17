//
//  SummaryView.swift
//  ScoreWatch
//
//  Povzetek po koncu dvoboja.
//

import SwiftUI

struct SummaryView: View {

    @EnvironmentObject private var engine: MatchEngine
    @EnvironmentObject private var workout: WorkoutManager

    let onNewMatch: () -> Void

    init(onNewMatch: @escaping () -> Void) {
        self.onNewMatch = onNewMatch
    }

    private var didWin: Bool { engine.state.winner == .me }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: didWin ? "trophy.fill" : "hand.thumbsup")
                    .font(.system(size: 26))
                    .foregroundStyle(didWin ? .yellow : .secondary)
                    .padding(.top, 4)

                Text(didWin ? "Zmaga" : "Poraz")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text(engine.finalScoreLine.isEmpty
                     ? "\(engine.state.pointsMe) : \(engine.state.pointsOpponent)"
                     : engine.finalScoreLine)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Divider().padding(.vertical, 2)

                statRow("Trajanje", durationText)
                statRow("Točke", "\(engine.state.totalPoints)")
                if engine.state.setsMe + engine.state.setsOpponent > 0 {
                    statRow("Seti", "\(engine.state.setsMe) : \(engine.state.setsOpponent)")
                }
                if workout.heartRate > 0 {
                    statRow("Srčni utrip", "\(Int(workout.heartRate)) bpm")
                }
                if workout.activeEnergy > 0 {
                    statRow("Energija", "\(Int(workout.activeEnergy)) kcal")
                }

                Button(action: onNewMatch) {
                    Text("NOV DVOBOJ")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
                .padding(.top, 6)
            }
            .padding(.horizontal, 6)
        }
    }

    private var durationText: String {
        let total = Int(engine.elapsed)
        let h = total / 3600, m = (total % 3600) / 60
        return h > 0 ? "\(h) h \(m) min" : "\(m) min"
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
    }
}
