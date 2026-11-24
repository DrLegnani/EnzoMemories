import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var mediaManager = MediaManager()
    @State private var splashFinished: Bool = false
    @State private var selectedTab: Int = 0
    @State private var showLetter: Bool = false
    @State private var showSlideshow: Bool = false
    @State private var selectedVideoURL: URL? = nil
    @State private var selectedVideoTitle: String = "Vídeo"
    
    private let tabs = [
        ("Missão Principal", "crown.fill"),
        ("Snapmatic (Fotos)", "camera.fill"),
        ("Cutscenes (Vídeos)", "film.fill"),
        ("Aliados & Crew", "person.3.fill")
    ]
    
    var body: some View {
        ZStack {
            if !splashFinished {
                GTAVISplashScreen(isFinished: $splashFinished, mediaManager: mediaManager)
                    .transition(.opacity)
            } else {
                mainAppContent
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showLetter) {
            GTALetterReaderView(carta: mediaManager.config.cartaPais, mediaManager: mediaManager)
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            SlideshowView(fotos: mediaManager.fotos)
        }
        .fullScreenCover(item: Binding(
            get: { selectedVideoURL.map { IdentifiableURL(url: $0, title: selectedVideoTitle) } },
            set: { selectedVideoURL = $0?.url }
        )) { item in
            VideoPlayerModal(videoURL: item.url, title: item.title)
        }
    }
    
    // Conteúdo Principal do App (Tema GTA VI)
    private var mainAppContent: some View {
        ZStack {
            // Fundo escuro com sutil gradiente Vice City
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.10, green: 0.06, blue: 0.12),
                    Color(red: 0.04, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 14) {
                // HUD Superior estilo GTA
                HStack(alignment: .center) {
                    // Logo e Título
                    HStack(spacing: 10) {
                        Text("IX")
                            .font(.system(size: 28, weight: .black, design: .serif))
                            .italic()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 1.0, green: 0.5, blue: 0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("ENZO • MEMORIES")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .tracking(2)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Text("MISSION: 9º ANO")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                Text("[COMPLETED]")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.green)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Status de Respeito
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                        Text("RESPECT +")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.12))
                    .cornerRadius(12)
                    
                    // Rádio / Música (com suporte a múltiplas faixas)
                    HStack(spacing: 4) {
                        Button(action: { mediaManager.toggleMusic() }) {
                            HStack(spacing: 6) {
                                Image(systemName: mediaManager.isMusicPlaying ? "radio.fill" : "radio")
                                    .font(.system(size: 13))
                                    .foregroundColor(mediaManager.isMusicPlaying ? Color(red: 1.0, green: 0.2, blue: 0.6) : .white)
                                Text(mediaManager.isMusicPlaying ? "RÁDIO: \(mediaManager.currentTrackName.uppercased())" : "RÁDIO: OFF")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                        
                        if mediaManager.playlist.count > 1 {
                            Button(action: { mediaManager.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 11))
                                    .padding(8)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Rever Intro GTA
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            splashFinished = false
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles.tv.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            Text("INTRO")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    }
                    
                    // Recarregar
                    Button(action: { mediaManager.loadMediaFiles() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                // Seletor de Abas em Estilo HUD Neon
                HStack(spacing: 8) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        let tab = tabs[index]
                        let isSelected = selectedTab == index
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.1)
                                    .font(.system(size: 13))
                                Text(tab.0.uppercased())
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .tracking(1)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                isSelected ?
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.15, blue: 0.55), Color(red: 1.0, green: 0.45, blue: 0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                            .cornerRadius(14)
                            .shadow(color: isSelected ? Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.5) : Color.clear, radius: 8)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                // Conteúdo
                ZStack {
                    switch selectedTab {
                    case 0:
                        GTAMainMissionTab(mediaManager: mediaManager,
                                          showLetter: $showLetter,
                                          showSlideshow: $showSlideshow,
                                          selectedVideoURL: $selectedVideoURL,
                                          selectedVideoTitle: $selectedVideoTitle)
                    case 1:
                        GTAPhotosTab(mediaManager: mediaManager, showSlideshow: $showSlideshow)
                    case 2:
                        GTAVideosTab(mediaManager: mediaManager,
                                     selectedVideoURL: $selectedVideoURL,
                                     selectedVideoTitle: $selectedVideoTitle)
                    case 3:
                        GTARecadosTab(mediaManager: mediaManager)
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }
}

// Wrapper para URL em modal
struct IdentifiableURL: Identifiable {
    var id: String { url.absoluteString }
    let url: URL
    let title: String
}

// MARK: - Aba Missão Principal (Estilo GTA VI)
struct GTAMainMissionTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var showLetter: Bool
    @Binding var showSlideshow: Bool
    @Binding var selectedVideoURL: URL?
    @Binding var selectedVideoTitle: String
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Banner "MISSION PASSED"
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 5) {
                            ForEach(0..<6, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.white, Color(red: 0.72, green: 0.78, blue: 0.86)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.white.opacity(0.45), radius: 4)
                            }
                        }
                        Spacer()
                        Text("LEVEL UNLOCKED: ENSINO MÉDIO")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    }
                    
                    Text("MISSION PASSED: O 9º ANO É SEU!")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Você venceu cada prova, cada fase e construiu histórias épicas no Colégio Alfa. Essa caixinha é o save point das suas melhores memórias até aqui.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.8))
                }
                .padding(22)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.08, blue: 0.25), Color(red: 0.10, green: 0.08, blue: 0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 0.0, green: 0.95, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
                
                // Cards de Destaque Lado a Lado
                HStack(spacing: 14) {
                    // Card Carta dos Pais
                    Button(action: { showLetter = true }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "envelope.badge.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.6))
                                Spacer()
                                Text("CARTA OFICIAL")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("A Carta dos Pais")
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Nossas palavras sinceras para você nessa nova fase da vida.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Text("ABRIR MENSAGEM")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .tracking(1)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.7))
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 175)
                        .background(Color(red: 0.12, green: 0.08, blue: 0.18))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    
                    // Card Vídeo dos Pais
                    Button(action: {
                        if let videoFile = mediaManager.config.videoPaisFile,
                           let url = mediaManager.resolveMediaURL(filename: videoFile) {
                            selectedVideoURL = url
                            selectedVideoTitle = "Vídeo dos Pais"
                        } else if let first = mediaManager.videos.first {
                            selectedVideoURL = first
                            selectedVideoTitle = "Vídeo Especial"
                        } else {
                            showLetter = true
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                Spacer()
                                Text("CUTSCENE")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vídeo dos Pais")
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Um recado em vídeo para você assistir de olhos bem abertos.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Text("DAR PLAY")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .tracking(1)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 175)
                        .background(Color(red: 0.08, green: 0.12, blue: 0.18))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
                
                // Card Snapmatic Slideshow
                Button(action: { showSlideshow = true }) {
                    HStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.2))
                            .frame(width: 54, height: 54)
                            .background(Color(red: 1.0, green: 0.5, blue: 0.2).opacity(0.15))
                            .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("SNAPMATIC • MEMÓRIAS DA INFÂNCIA AO 9º ANO")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .tracking(1)
                                .foregroundColor(.white)
                            Text("\(mediaManager.fotos.count) fotos sincronizadas • Iniciar apresentação cinematográfica")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.65))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.2))
                    }
                    .padding(16)
                    .background(Color(red: 0.12, green: 0.09, blue: 0.14))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Aba Fotos (Snapmatic)
struct GTAPhotosTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var showSlideshow: Bool
    
    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.2))
                    Text("GALERIA SNAPMATIC (\(mediaManager.fotos.count))")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: { showSlideshow = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("APRESENTAÇÃO")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 1.0, green: 0.5, blue: 0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }
            .padding(.top, 4)
            
            if mediaManager.fotos.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text("NENHUMA FOTO CARREGADA AINDA")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                    Text("Copie as fotos para a pasta do app no iPad.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.4))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(mediaManager.fotos, id: \.self) { url in
                            if let uiImage = UIImage(contentsOfFile: url.path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(minHeight: 140, maxHeight: 180)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        showSlideshow = true
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Aba Vídeos (Cutscenes)
struct GTAVideosTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var selectedVideoURL: URL?
    @Binding var selectedVideoTitle: String
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "film.fill")
                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                Text("CUTSCENES DA SUA HISTÓRIA (\(mediaManager.videos.count))")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
            
            if mediaManager.videos.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "video.slash")
                        .font(.system(size: 50))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text("NENHUM VÍDEO ADICIONADO AINDA")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                    Text("Copie vídeos (.mp4 ou .mov) para a pasta do app.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.4))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mediaManager.videos, id: \.self) { url in
                            Button(action: {
                                selectedVideoURL = url
                                selectedVideoTitle = url.deletingPathExtension().lastPathComponent
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ZStack {
                                        Color(red: 0.12, green: 0.09, blue: 0.16)
                                            .aspectRatio(16/9, contentMode: .fit)
                                            .cornerRadius(16)
                                        
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                    }
                                    
                                    Text(url.deletingPathExtension().lastPathComponent.uppercased())
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                .padding(12)
                                .background(Color(red: 0.09, green: 0.07, blue: 0.12))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Aba Recados (Aliados & Crew)
struct GTARecadosTab: View {
    @ObservedObject var mediaManager: MediaManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 340), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                Text("CREW • RECADOS DE QUEM FECHA COM VOCÊ")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(mediaManager.config.recados) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(item.de.uppercased())
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                if let rel = item.relacao {
                                    Text(rel.uppercased())
                                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.7))
                                }
                            }
                            
                            Text(item.texto)
                                .font(.system(size: 14))
                                .lineSpacing(4)
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        .padding(18)
                        .background(Color(red: 0.10, green: 0.08, blue: 0.14))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Leitor da Carta Tema GTA
struct GTALetterReaderView: View {
    let carta: String
    @ObservedObject var mediaManager: MediaManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.04, blue: 0.09)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                        Text("A CARTA DOS PAIS")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(carta)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .lineSpacing(10)
                            .foregroundColor(Color(white: 0.92))
                            .padding(.vertical, 16)
                        
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("COM TODO O AMOR E ORGULHO DO MUNDO,")
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                Text("Seus Pais ❤️")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(30)
                    .background(Color(red: 0.10, green: 0.07, blue: 0.14))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.5), Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                }
            }
        }
    }
}
