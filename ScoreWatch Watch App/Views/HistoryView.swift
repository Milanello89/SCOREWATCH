//
//  HistoryView.swift
//  ScoreWatch
//
//  Zgodovina odigranih dvobojev.
//

import SwiftUI

struct HistoryView: View {

    @EnvironmentObject private var store: MatchStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !store.matches.isEmpty {
                    Section {
                        HStack {
                            Text("Delež zmag")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(store.winRate * 100)) %")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                    }
                }

                Section {
                    ForEach(store.matches) { match in
                        HStack(spacing: 8) {
                            Image(systemName: match.sport.symbol)
                                .font(.system(size: 12))
                                .foregroundStyle(match.winnerIsMe ? .green : .orange)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(match.scoreLine)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("\(match.dateText) · \(match.durationText)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        store.deleteAll()
                        dismiss()
                    } label: {
                        Label("Počisti zgodovino", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Zgodovina")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
