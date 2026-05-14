//
//  CheckForUpdatesView.swift
//  Applite
//
//  Created by Milán Várady on 2023. 07. 29..
//
// Copy pasta from: https://sparkle-project.org/documentation/programmatic-setup/

import SwiftUI
import Sparkle
import Combine

/// This view model class publishes when new updates can be checked by the user
@MainActor
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

/// A button that opens sparkle updater and checks for available updates
struct CheckForUpdatesView<T: View>: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    let label: ()->T
    
    init(updater: SPUUpdater, @ViewBuilder label: @escaping ()->T) {
        self.updater = updater
        
        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
        
        self.label = label
    }
    
    var body: some View {
        Button(action: updater.checkForUpdates, label: label)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

