//
//  ContentView.swift
//  ScoreWatch
//
//  Usmerjevalnik med zasloni: nastavitve → dvoboj → povzetek.
//

import SwiftUI

enum Route {
    case setup
    case match
    case summary
}

struct ContentView: View {

    @EnvironmentObject private var engine: MatchEngine
    @EnvironmentObject private var workout: WorkoutManager
    @EnvironmentObject private var store: MatchStore

    @State private var route: Route = .setup

    var body: some View {
        Group {
            switch route {
            case .setup:
                SetupView { settings in
                    engine.start(with: settings)
                    workout.start(sport: settings.sport)
                    route = .match
                }

            case .match:
                MatchView(
                    onFinish: { finishMatch() },
                    onAbandon: { abandonMatch() }
                )

            case .summary:
                SummaryView {
                    route = .setup
                }
            }
        }
        .onAppear { workout.requestAuthorization() }
        .onChange(of: engine.state.isFinished) { _, finished in
            if finished { finishMatch() }
        }
    }

    private func finishMatch() {
        guard route == .match else { return }
        workout.end()
        saveRecord()
        route = .summary
    }

    private func abandonMatch() {
        workout.end()
        route = .setup
    }

    private func saveRecord() {
        let state = engine.state
        let record = MatchRecord(
            date: engine.startDate,
            sport: engine.settings.sport,
            mode: engine.settings.mode,
            scoreLine: engine.finalScoreLine.isEmpty
                ? "\(state.pointsMe):\(state.pointsOpponent)"
                : engine.finalScoreLine,
            setsMe: state.setsMe,
            setsOpponent: state.setsOpponent,
            winnerIsMe: state.winner == .me,
            duration: engine.elapsed,
            totalPoints: state.totalPoints,
            averageHeartRate: workout.heartRate > 0 ? workout.heartRate : nil
        )
        store.add(record)
    }
}
