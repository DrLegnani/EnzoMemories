import SwiftUI

@main
struct EnzoMemoriesApp: App {
    init() {
        // Impede que a tela do iPad desligue automaticamente durante a exibição
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
