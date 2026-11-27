import SwiftUI
import AVKit

struct VideoPlayerModal: View {
    let videoURL: URL
    let title: String
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        player?.pause()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            let p = AVPlayer(url: videoURL)
            self.player = p
            p.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
