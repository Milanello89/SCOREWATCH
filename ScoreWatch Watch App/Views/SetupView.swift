//
//  SetupView.swift
//  ScoreWatch
//
//  Nastavitev dvoboja pred začetkom. Vse se pomika z digitalno krono.
//

import SwiftUI

struct SetupView: View {

    @EnvironmentObject private var store: MatchStore

    @AppStorage("last.sport")      private var sportRaw: String = Sport.tennis.rawValue
    @AppStorage("last.mode")       private var modeRaw: String = ScoringMode.official.rawValue
    @AppStorage("last.sets")       private var setsToPlay: Int = 3
    @AppStorage("last.noAd")       private var noAd: Bool = false
    @AppStorage("last.matchTB")    private var matchTiebreak: Bool = false
    @AppStorage("last.server")     private var serverRaw: Int = Player.me.rawValue

    @State private var showHistory = false

    let onStart: (MatchSettings) -> Void

    init(onStart: @escaping (MatchSettings) -> Void) {
        self.onStart = onStart
    }

    private var sport: Sport { Sport(rawValue: sportRaw) ?? .tennis }
    private var mode: ScoringMode { ScoringMode(rawValue: modeRaw) ?? .official }

    var body: some View {
        NavigationStack {
            List {
                sportSection
                modeSection

                if mode == .official {
                    formatSection
                }

                serverSection
                startSection

                if !store.matches.isEmpty {
                    Section {
                        Button {
                            showHistory = true
                        } label: {
                            Label("Zgodovina (\(store.matches.count))", systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
            }
            .navigationTitle("Nov dvoboj")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHistory) { HistoryView() }
        }
    }

    // MARK: - Sekcije

    private var sportSection: some View {
        Section("Šport") {
            ForEach(Sport.allCases) { option in
                Button {
                    sportRaw = option.rawValue
                    if option == .badminton { setsToPlay = min(setsToPlay, 3) }
                } label: {
                    HStack {
                        Image(systemName: option.symbol)
                            .foregroundStyle(sport == option ? Color.accentColor : .secondary)
                        Text(option.title)
                        Spacer()
                        if sport == option {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var modeSection: some View {
        Section("Način štetja") {
            ForEach(ScoringMode.allCases) { option in
                Button {
                    modeRaw = option.rawValue
                } label: {
                    HStack {
                        Text(option.title)
                        Spacer()
                        if mode == option {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var formatSection: some View {
        Section("Format") {
            Picker("Št. setov", selection: $setsToPlay) {
                Text("1 set").tag(1)
                Text("Na 2 dobljena").tag(3)
                if sport == .tennis {
                    Text("Na 3 dobljene").tag(5)
                }
            }

            if sport == .tennis {
                Toggle("Brez prednosti", isOn: $noAd)
                Toggle("Odločilni set do 10", isOn: $matchTiebreak)
            }
        }
    }

    private var serverSection: some View {
        Section("Prvi servis") {
            Picker("Servira", selection: $serverRaw) {
                Text("Jaz").tag(Player.me.rawValue)
                Text("Nasprotnik").tag(Player.opponent.rawValue)
            }
        }
    }

    private var startSection: some View {
        Section {
            Button {
                var settings = MatchSettings()
                settings.sport = sport
                settings.mode = mode
                settings.setsToPlay = mode == .official ? setsToPlay : 1
                settings.noAd = sport == .tennis && noAd
                settings.matchTiebreak = sport == .tennis && matchTiebreak
                settings.firstServer = Player(rawValue: serverRaw) ?? .me
                onStart(settings)
            } label: {
                Text("ZAČNI")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .tint(.green)
        }
    }
}
