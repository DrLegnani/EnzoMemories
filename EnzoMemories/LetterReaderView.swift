import SwiftUI

struct LetterReaderView: View {
    let carta: String
    @ObservedObject var mediaManager: MediaManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.11)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header com fechar e música
                HStack {
                    Label("Carta dos Pais", systemImage: "envelope.open.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.40))
                    
                    Spacer()
                    
                    Button(action: { mediaManager.toggleMusic() }) {
                        HStack(spacing: 6) {
                            Image(systemName: mediaManager.isMusicPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            Text(mediaManager.isMusicPlaying ? "Música Ativa" : "Música Pausada")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    }
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(white: 0.6))
                    }
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Texto da carta em ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(carta)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .lineSpacing(10)
                            .foregroundColor(Color(red: 0.92, green: 0.92, blue: 0.94))
                            .padding(.vertical, 24)
                            .padding(.horizontal, 8)
                        
                        HStack {
                            Spacer()
                            Text("Com todo o amor, Seus Pais ❤️")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.40))
                        }
                        .padding(.top, 16)
                    }
                    .padding(32)
                    .background(Color(red: 0.11, green: 0.12, blue: 0.16))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                }
            }
        }
        .onAppear {
            mediaManager.startMusicIfAvailable()
        }
    }
}
