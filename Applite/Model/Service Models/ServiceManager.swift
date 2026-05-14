//
//  ServiceManager.swift
//  Applite
//

import Foundation
import OSLog

@MainActor
final class ServiceManager: ObservableObject {
    static let shared = ServiceManager()

    @Published var services: [BrewService] = []
    @Published var isLoading: Bool = false
    @Published var activeTasks: Set<String> = []

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ServiceManager")

    private init() {}

    // MARK: - Load

    func loadServices() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let output = try await Shell.runBrewCommand(["services", "list"])
            services = BrewService.parseAll(output: output)
        } catch {
            logger.error("Failed to load services: \(error.localizedDescription)")
        }
    }

    // MARK: - Control

    func start(service: BrewService) async {
        await runServiceCommand(["services", "start", service.name], service: service)
    }

    func stop(service: BrewService) async {
        await runServiceCommand(["services", "stop", service.name], service: service)
    }

    func restart(service: BrewService) async {
        await runServiceCommand(["services", "restart", service.name], service: service)
    }

    private func runServiceCommand(_ args: [String], service: BrewService) async {
        activeTasks.insert(service.name)
        defer { activeTasks.remove(service.name) }
        do {
            try await Shell.runBrewCommand(args)
            await loadServices()
        } catch {
            logger.error("Service command \(args.joined(separator: " ")) failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Install Formula

    func installAndStart(formula: String) async {
        activeTasks.insert(formula)
        defer { activeTasks.remove(formula) }
        do {
            // Install as formula (not cask)
            try await Shell.runBrewCommand(["install", formula])
            try await Shell.runBrewCommand(["services", "start", formula])
            await loadServices()
        } catch {
            logger.error("Install formula \(formula) failed: \(error.localizedDescription)")
        }
    }
}
