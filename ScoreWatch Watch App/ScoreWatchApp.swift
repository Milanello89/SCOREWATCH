//
//  ScoreWatchApp.swift
//  ScoreWatch – vodenje rezultata za tenis in badminton
//

import SwiftUI

@main
struct ScoreWatch_Watch_AppApp: App {

    @StateObject private var engine = MatchEngine()
    @StateObject private var workout = WorkoutManager()
    @StateObject private var store = MatchStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .environmentObject(workout)
                .environmentObject(store)
        }
    }
}
