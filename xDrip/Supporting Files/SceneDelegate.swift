//
//  SceneDelegate.swift
//  xdrip
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)

        let rootVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()!

        window.rootViewController = rootVC
        self.window = window
        window.makeKeyAndVisible()

        // ---- عرض شاشة البريد عند أول تشغيل ----
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
           // UserDefaults.standard.removeObject(forKey: "userEmail")

            let savedEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""

            if savedEmail.isEmpty {
                let popup = EmailPopupViewController()
                popup.modalPresentationStyle = .formSheet

                popup.onSubmit = { email in
                    UserDefaults.standard.set(email, forKey: "userEmail")
                    sendEmailToServer(email: email)
                }

                rootVC.present(popup, animated: true)
            }
        }
    }
}
