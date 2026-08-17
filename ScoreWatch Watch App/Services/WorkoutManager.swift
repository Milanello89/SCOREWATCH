//
//  WorkoutManager.swift
//  ScoreWatch
//
//  KLJUČNI DEL APLIKACIJE.
//
//  Brez aktivne vadbene seje watchOS po nekaj sekundah zatemni zaslon in
//  aplikacijo pošlje v ozadje – kar pomeni, da je štetje rezultata med igro
//  neuporabno. Ko teče HKWorkoutSession, aplikacija ostane v ospredju ves
//  čas dvoboja, zaslon pa v načinu Always-On prikazuje rezultat.
//
//  Stranska korist: dvoboj se zapiše med vadbe (trajanje, srčni utrip,
//  poraba energije) in se prikaže v aplikaciji Fitness na iPhonu.
//

import Foundation
import HealthKit
import WatchKit

final class WorkoutManager: NSObject, ObservableObject {

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var isRunning = false
    @Published var isAuthorized = false

    // MARK: - Dovoljenja

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.activitySummaryType()
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            DispatchQueue.main.async { self.isAuthorized = success }
        }
    }

    // MARK: - Začetek in konec seje

    func start(sport: Sport) {
        guard HKHealthStore.isHealthDataAvailable(), session == nil else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = (sport == .tennis) ? .tennis : .badminton
        configuration.locationType = .indoor

        do {
            let newSession = try HKWorkoutSession(healthStore: healthStore,
                                                  configuration: configuration)
            let newBuilder = newSession.associatedWorkoutBuilder()
            newBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                            workoutConfiguration: configuration)
            newSession.delegate = self
            newBuilder.delegate = self

            let startDate = Date()
            newSession.startActivity(with: startDate)
            newBuilder.beginCollection(withStart: startDate) { _, _ in }

            session = newSession
            builder = newBuilder
            isRunning = true
        } catch {
            // Če seje ni mogoče zagnati (npr. v simulatorju), aplikacija
            // še vedno deluje – le zaslon se lahko prej zatemni.
            isRunning = false
        }
    }

    func end() {
        guard let session, let builder else { return }
        session.end()
        builder.endCollection(withEnd: Date()) { _, _ in
            builder.finishWorkout { _, _ in }
        }
        self.session = nil
        self.builder = nil
        isRunning = false
    }

    /// Zaklep zaslona proti dežju in potu (Water Lock).
    /// Odklene se z zavrtljajem digitalne krone.
    func enableWaterLock() {
        WKInterfaceDevice.current().enableWaterLock()
    }
}

// MARK: - Delegat vadbene seje

extension WorkoutManager: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async { self.isRunning = (toState == .running) }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        DispatchQueue.main.async { self.isRunning = false }
    }
}

// MARK: - Delegat zbiranja podatkov

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {

        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else { continue }

            switch quantityType.identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                let unit = HKUnit.count().unitDivided(by: .minute())
                let value = statistics.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                DispatchQueue.main.async { self.heartRate = value }

            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                let value = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                DispatchQueue.main.async { self.activeEnergy = value }

            default:
                break
            }
        }
    }
}
