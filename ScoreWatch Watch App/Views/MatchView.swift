//
//  MatchView.swift
//  ScoreWatch
//
//  Glavni zaslon med dvobojem.
//
//  Upravljanje:
//    • kratek klik na ZGORNJO polovico  → točka zame
//    • kratek klik na SPODNJO polovico  → točka za nasprotnika
//    • dolg pritisk (0,4 s) kjer koli   → razveljavi zadnjo točko
//    • klik na zgornjo vrstico          → dodatne možnosti
//
//  Kratek klik se odzove takoj – med njim in dolgim pritiskom ni zakasnitve.
//

import SwiftUI

struct MatchView: View {

    @EnvironmentObject private var engine: MatchEngine
    @EnvironmentObject private var workout: WorkoutManager

    let onFinish: () -> Void
    let onAbandon: () -> Void

    init(onFinish: @escaping () -> Void, onAbandon: @escaping () -> Void) {
        self.onFinish = onFinish
        self.onAbandon = onAbandon
    }

    @State private var showOptions = false
    @State private var flash: Player?
    @State private var undoFlash = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                VStack(spacing: 2) {
                    zone(for: .me)
                    zone(for: .opponent)
                }
                situationBadge
                if undoFlash { undoOverlay }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showOptions) { optionsSheet }
    }

    // MARK: - Glava

    private var header: some View {
        HStack(spacing: 6) {
            Text(engine.setSummary.isEmpty ? engine.settings.sport.title : engine.setSummary)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 2)

            if workout.heartRate > 0 {
                Label("\(Int(workout.heartRate))", systemImage: "heart.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red)
                    .labelStyle(.titleAndIcon)
            }

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(elapsedText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
        .frame(height: 22)
        .contentShape(Rectangle())
        .onTapGesture { showOptions = true }
    }

    private var elapsedText: String {
        let total = Int(engine.elapsed)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Tap cona za posameznega igralca

    private func zone(for player: Player) -> some View {
        let isMe = player == .me
        let base: Color = isMe ? .green : .orange
        let isServing = engine.state.server == player && engine.settings.mode == .official

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(base.opacity(flash == player ? 0.55 : 0.22))

            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isMe ? "JAZ" : "NASPROTNIK")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(base)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if isServing {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(base)
                    }
                }
                .frame(width: 44, alignment: .leading)

                Spacer(minLength: 0)

                Text(engine.displayPoints(for: player))
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Spacer(minLength: 0)

                VStack(spacing: 1) {
                    Text("\(player == .me ? engine.state.setsMe : engine.state.setsOpponent)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("seti")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 28)
                .opacity(engine.settings.mode == .official ? 1 : 0)
            }
            .padding(.horizontal, 6)
        }
        .contentShape(Rectangle())
        .onTapGesture { award(player) }
        .onLongPressGesture(minimumDuration: 0.4) { undo() }
        .animation(.easeOut(duration: 0.15), value: flash)
    }

    // MARK: - Oznaka stanja (žogica za set, neodločeno, podaljšana igra)

    @ViewBuilder
    private var situationBadge: some View {
        if let label = engine.situationLabel {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(.black.opacity(0.75)))
                .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 0.5))
                .transition(.opacity)
        }
    }

    private var undoOverlay: some View {
        Label("Razveljavljeno", systemImage: "arrow.uturn.backward")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(.blue))
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Akcije

    private func award(_ player: Player) {
        let event = engine.award(player)
        Haptics.play(for: event)
        withAnimation { flash = player }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation { if flash == player { flash = nil } }
        }
    }

    private func undo() {
        guard engine.undo() else {
            // Ni česa razveljaviti – opozorilni otip.
            Haptics.play(for: .ignored)
            return
        }
        Haptics.play(for: .undo)
        withAnimation { undoFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation { undoFlash = false }
        }
    }

    // MARK: - Možnosti

    private var optionsSheet: some View {
        List {
            Section {
                Button {
                    showOptions = false
                    undo()
                } label: {
                    Label("Razveljavi točko", systemImage: "arrow.uturn.backward")
                }
                .disabled(!engine.canUndo)

                Button {
                    showOptions = false
                    workout.enableWaterLock()
                } label: {
                    Label("Zakleni zaslon", systemImage: "drop.fill")
                }
            } footer: {
                Text("Zaklep odkleneš z zavrtljajem digitalne krone.")
            }

            Section {
                Button(role: .destructive) {
                    showOptions = false
                    onFinish()
                } label: {
                    Label("Zaključi in shrani", systemImage: "flag.checkered")
                }

                Button(role: .destructive) {
                    showOptions = false
                    onAbandon()
                } label: {
                    Label("Prekini brez shranjevanja", systemImage: "xmark")
                }
            }
        }
        .navigationTitle("Možnosti")
    }
}
