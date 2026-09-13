//
//  XdripApp.swift
//  xdrip
//
//  Created by Paul Plant on 12/7/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import SwiftUI
import UIKit

/// SwiftUI application entry point.
///
/// RootApplicationCoordinator owns the long-lived application services, while RootTabView owns
/// all root presentation and navigation. AppDelegate remains attached only for iOS callbacks that
/// do not yet have a SwiftUI equivalent, such as supported orientations and Home Screen actions.
@main @MainActor struct XdripApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var stateModel: RootTabStateModel

    private let applicationCoordinator: RootApplicationCoordinator
    private let tabTitles: RootTabTitles

    init() {
        let applicationCoordinator = RootApplicationCoordinator()
        let stateModel = RootTabStateModel()

        self.applicationCoordinator = applicationCoordinator
        self.tabTitles = RootTabTitles(
            home: NSLocalizedString("rootTab.home", tableName: "RootTab", bundle: .main, value: "Home", comment: "Home tab title."),
            treatments: NSLocalizedString("rootTab.treatments", tableName: "RootTab", bundle: .main, value: "Treatments", comment: "Treatments tab title."),
            statistics: NSLocalizedString("rootTab.statistics", tableName: "RootTab", bundle: .main, value: "Statistics", comment: "Statistics tab title."),
            devices: NSLocalizedString("rootTab.devices", tableName: "RootTab", bundle: .main, value: "Devices", comment: "Devices tab title."),
            settings: NSLocalizedString("rootTab.settings", tableName: "RootTab", bundle: .main, value: "Settings", comment: "Settings tab title.")
        )
        _stateModel = StateObject(wrappedValue: stateModel)

        applicationCoordinator.start(rootTabStateModel: stateModel)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Keep rotation resizes on the app palette instead of exposing the system window.
                ConstantsAppColors.background
                    .ignoresSafeArea()

                RootTabView(
                    stateModel: stateModel,
                    applicationCoordinator: applicationCoordinator,
                    tabTitles: tabTitles
                )
            }
            .background(ConstantsAppColors.background)
            .onOpenURL(perform: stateModel.receiveIncomingBackup)
            .task { await presentEmailPromptIfNeeded() }
        }
    }
}

private extension XdripApp {

    /// Presents the one-time email prompt after launch, unless an email was already
    /// submitted or the user declined twice (see EmailPromptState). A short settle delay
    /// keeps it clear of any root presentation racing at startup; if the root is still
    /// busy the prompt is retried once, otherwise it waits for the next launch.
    func presentEmailPromptIfNeeded() async {
        guard EmailPromptState.shouldPrompt() else { return }

        for nanoseconds in [UInt64(1_000_000_000), UInt64(3_000_000_000)] {
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard let root = UIApplication.foregroundKeyRootViewController(), root.presentedViewController == nil else { continue }

            let popup = EmailPopupViewController()
            popup.modalPresentationStyle = .formSheet

            popup.onSubmit = { email in
                EmailPromptState.registerSubmission(email: email)
                EmailUploader.send(email: email)
            }
            popup.onDecline = {
                EmailPromptState.registerDecline()
            }

            root.present(popup, animated: true)
            return
        }
    }
}

private extension UIApplication {

    /// Root view controller of the key window in the foreground-active scene.
    @MainActor static func foregroundKeyRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            .flatMap { $0.windows.first(where: \.isKeyWindow) }?
            .rootViewController
    }
}
