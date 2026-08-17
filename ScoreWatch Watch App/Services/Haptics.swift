//
//  Haptics.swift
//  ScoreWatch
//
//  Vsak dogodek ima svoj otip, da med igro veš, da je klik registriran,
//  ne da bi moral pogledati na uro.
//

import WatchKit

enum Haptics {

    static func play(for event: ScoreEvent) {
        switch event {
        case .point:
            WKInterfaceDevice.current().play(.click)

        case .gameWon:
            WKInterfaceDevice.current().play(.success)

        case .setWon:
            WKInterfaceDevice.current().play(.notification)

        case .matchWon:
            // Trojni otip – nedvoumen konec dvoboja.
            let device = WKInterfaceDevice.current()
            device.play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { device.play(.success) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) { device.play(.notification) }

        case .undo:
            WKInterfaceDevice.current().play(.retry)

        case .ignored:
            WKInterfaceDevice.current().play(.failure)
        }
    }
}
