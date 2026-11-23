import SwiftUI

struct SlideshowView: View {
    let fotos: [URL]
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = true
    @State private var timer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if fotos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Nenhuma foto encontrada")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    Text("Adicione fotos (.jpg ou .png) na pasta do app.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            } else {
                // Foto Atual com animação de transição
                let currentURL = fotos[currentIndex]
                if let uiImage = UIImage(contentsOfFile: currentURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                        .id(currentIndex)
                }
                
                // Controles de toque invisíveis (esquerda volta, direita avança)
                HStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            previousPhoto()
                        }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            nextPhoto()
                        }
                }
                
                // Overlay superior com contador e fechar
                VStack {
                    HStack {
                        Text("\(currentIndex + 1) de \(fotos.count)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        Button(action: { isPlaying.toggle() }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
        }
        .onReceive(timer) { _ in
            if isPlaying && !fotos.isEmpty {
                nextPhoto()
            }
        }
    }
    
    private func nextPhoto() {
        withAnimation {
            currentIndex = (currentIndex + 1) % fotos.count
        }
    }
    
    private func previousPhoto() {
        withAnimation {
            currentIndex = (currentIndex - 1 + fotos.count) % fotos.count
        }
    }
}
