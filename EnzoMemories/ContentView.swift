import SwiftUI
import AVKit
import AVFoundation
import ImageIO

struct ContentView: View {
    @StateObject private var mediaManager = MediaManager()
    @State private var splashFinished: Bool = false
    @State private var selectedTab: Int = 0
    @State private var showLetter: Bool = false
    @State private var showSlideshow: Bool = false
    @State private var slideshowStartIndex: Int = 0
    @State private var selectedVideoURL: URL? = nil
    @State private var selectedVideoTitle: String = "Vídeo"
    @State private var selectedIsFamilyVideo: Bool = false
    
    private let tabs = [
        ("Missão Principal", "crown.fill"),
        ("Snapmatic (Fotos)", "camera.fill"),
        ("Cutscenes (Vídeos)", "film.fill"),
        ("Crew", "person.3.fill")
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
            SlideshowView(fotos: mediaManager.fotos, initialIndex: slideshowStartIndex)
        }
        .fullScreenCover(item: Binding(
            get: { selectedVideoURL.map { IdentifiableURL(url: $0, title: selectedVideoTitle, isFamilyVideo: selectedIsFamilyVideo) } },
            set: {
                if $0 == nil {
                    selectedVideoURL = nil
                    if selectedIsFamilyVideo {
                        selectedIsFamilyVideo = false
                        mediaManager.restoreMusicVolume()
                    }
                } else {
                    selectedVideoURL = $0?.url
                }
            }
        )) { item in
            if item.url.pathExtension.lowercased() == "gif" {
                GTAGIFModal(gifURL: item.url, title: item.title)
            } else {
                VideoPlayerModal(videoURL: item.url, title: item.title)
                    .onAppear {
                        if item.isFamilyVideo {
                            mediaManager.playTrack(matching: "In The Air Tonight", targetVolume: 0.28, loop: true)
                        }
                    }
            }
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
                        GTAPhotosTab(mediaManager: mediaManager,
                                     showSlideshow: $showSlideshow,
                                     slideshowStartIndex: $slideshowStartIndex)
                    case 2:
                        GTAVideosTab(mediaManager: mediaManager,
                                     selectedVideoURL: $selectedVideoURL,
                                     selectedVideoTitle: $selectedVideoTitle)
                    case 3:
                        GTARecadosTab(mediaManager: mediaManager,
                                      selectedVideoURL: $selectedVideoURL,
                                      selectedVideoTitle: $selectedVideoTitle,
                                      selectedIsFamilyVideo: $selectedIsFamilyVideo)
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
    var isFamilyVideo: Bool = false
}

// MARK: - Aba Missão Principal (Estilo GTA VI)
struct SelectedMemoryPresentation: Identifiable {
    let id = UUID()
    let startIndex: Int
}

struct GTAMainMissionTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var showLetter: Bool
    @Binding var showSlideshow: Bool
    @Binding var selectedVideoURL: URL?
    @Binding var selectedVideoTitle: String
    @State private var memoryViewer: SelectedMemoryPresentation? = nil
    
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
                            selectedIsFamilyVideo = true
                            selectedVideoURL = url
                            selectedVideoTitle = "Vídeo dos Pais"
                        } else if let first = mediaManager.videos.first {
                            selectedIsFamilyVideo = true
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

                // Seção Memórias • Mission Passed (Linha do Tempo 2010–2026)
                if !mediaManager.memoryEras.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(Color(red: 0.2, green: 0.95, blue: 0.6))
                                Text("MEMÓRIAS • MISSION PASSED (\(mediaManager.memories.count))")
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: {
                                memoryViewer = SelectedMemoryPresentation(startIndex: 0)
                            }) {
                                Text("VER LINHA DO TEMPO →")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(mediaManager.memoryEras) { era in
                                    Button(action: {
                                        memoryViewer = SelectedMemoryPresentation(startIndex: era.startIndex)
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ZStack(alignment: .topLeading) {
                                                if let first = era.items.first,
                                                   let url = Bundle.main.url(forResource: first.resourceName, withExtension: "jpg"),
                                                   let thumb = loadMemoryThumbnail(url: url, maxPixelSize: 420) {
                                                    Image(uiImage: thumb)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 220, height: 118)
                                                        .clipped()
                                                } else {
                                                    Rectangle()
                                                        .fill(Color.white.opacity(0.08))
                                                        .frame(width: 220, height: 118)
                                                }

                                                HStack(spacing: 4) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 10))
                                                    Text("MISSION PASSED • \(era.eraYears)")
                                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                                }
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(red: 0.2, green: 0.95, blue: 0.6))
                                                .cornerRadius(8)
                                                .padding(8)
                                            }
                                            .cornerRadius(14)

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(era.eraTitle)
                                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                Text(era.eraSubtitle)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color.white.opacity(0.68))
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                Text("\(era.items.count) fotos desbloqueadas")
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.7))
                                                    .padding(.top, 2)
                                            }
                                            .padding(.horizontal, 4)
                                        }
                                        .padding(10)
                                        .frame(width: 240, alignment: .leading)
                                        .background(Color(red: 0.11, green: 0.08, blue: 0.16))
                                        .cornerRadius(18)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(Color(red: 0.2, green: 0.95, blue: 0.6).opacity(0.28), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 6)
        }
        .fullScreenCover(item: $memoryViewer) { presentation in
            GTAMemoryTimelineViewer(memories: mediaManager.memories, initialIndex: presentation.startIndex)
        }
    }

    private func loadMemoryThumbnail(url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return UIImage(contentsOfFile: url.path)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(contentsOfFile: url.path)
    }
}

// MARK: - Aba Fotos (Snapmatic)
struct GTAPhotosTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var showSlideshow: Bool
    @Binding var slideshowStartIndex: Int
    
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
                
                Button(action: {
                    slideshowStartIndex = 0
                    showSlideshow = true
                }) {
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
                        ForEach(Array(mediaManager.fotos.enumerated()), id: \.element) { idx, url in
                            if let uiImage = loadGridThumbnail(url: url, maxPixelSize: 440) {
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
                                        slideshowStartIndex = idx
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

    private func loadGridThumbnail(url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return UIImage(contentsOfFile: url.path)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(contentsOfFile: url.path)
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
                            let cleanTitle = url.deletingPathExtension().lastPathComponent
                                .replacingOccurrences(of: #"^clip_(?:\d+|album_\d{4}-\d{2}-\d{2})_"#, with: "", options: .regularExpression)
                            let isGIF = url.pathExtension.lowercased() == "gif"
                            Button(action: {
                                selectedVideoURL = url
                                selectedVideoTitle = cleanTitle
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ZStack(alignment: .topTrailing) {
                                        CutsceneThumbnailView(url: url)
                                            .aspectRatio(16/9, contentMode: .fill)
                                            .frame(height: 145)
                                            .clipped()
                                            .cornerRadius(16)
                                        
                                        Image(systemName: isGIF ? "sparkles.tv.fill" : "play.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.92))
                                            .shadow(color: .black.opacity(0.75), radius: 8)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                                        Text(isGIF ? "GIF" : "VÍDEO")
                                            .font(.system(size: 9, weight: .black, design: .monospaced))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(isGIF ? Color(red: 1.0, green: 0.4, blue: 0.7) : Color(red: 0.0, green: 0.95, blue: 1.0))
                                            .cornerRadius(8)
                                            .padding(10)
                                    }
                                    
                                    Text(cleanTitle.uppercased())
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

// MARK: - Aba Crew (Pais, Família & Amigos)
struct GTARecadosTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var selectedVideoURL: URL?
    @Binding var selectedVideoTitle: String
    @Binding var selectedIsFamilyVideo: Bool
    
    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 340), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                Text("CREW • PAIS, FAMÍLIA & AMIGOS")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(mediaManager.config.recados) { item in
                        VStack(alignment: .leading, spacing: 12) {
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

                            if let vFile = item.videoFile,
                               let vURL = mediaManager.resolveMediaURL(filename: vFile) {
                                Button(action: {
                                    selectedIsFamilyVideo = true
                                    selectedVideoTitle = item.de
                                    selectedVideoURL = vURL
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 18))
                                        Text("ASSISTIR MENSAGEM EM VÍDEO")
                                            .font(.system(size: 11, weight: .black, design: .monospaced))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(red: 0.0, green: 0.95, blue: 1.0))
                                    .cornerRadius(12)
                                }
                            }
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

                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        Text(mediaManager.currentTrackName.uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    
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
        .onAppear {
            mediaManager.playTrack(matching: "In The Air Tonight")
        }
    }
}

// MARK: - Visualizador de Memórias (Mission Passed - Fotos + Vídeos Autoplay + Deslizar)
struct GTAMemoryTimelineViewer: View {
    let memories: [MemoryPhotoItem]
    let initialIndex: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex: Int = 0
    @State private var isAutoPlaying: Bool = true
    @State private var timer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

    private func goPrev() {
        guard !memories.isEmpty else { return }
        isAutoPlaying = false
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex = (currentIndex - 1 + memories.count) % memories.count
        }
    }

    private func goNext() {
        guard !memories.isEmpty else { return }
        isAutoPlaying = false
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex = (currentIndex + 1) % memories.count
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !memories.isEmpty {
                let item = memories[currentIndex]

                Group {
                    if let vName = item.videoResourceName,
                       let vExt = item.videoExt,
                       let vURL = Bundle.main.url(forResource: vName, withExtension: vExt) {
                        if vExt.lowercased() == "gif" {
                            AnimatedGIFView(url: vURL)
                                .ignoresSafeArea()
                                .id("\(item.id)_gif")
                        } else {
                            InlineAutoplayVideoView(url: vURL)
                                .ignoresSafeArea()
                                .id("\(item.id)_vid")
                        }
                    } else if let url = Bundle.main.url(forResource: item.resourceName, withExtension: "jpg"),
                              let img = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .ignoresSafeArea()
                            .id(item.id)
                            .transition(.opacity.animation(.easeInOut(duration: 0.35)))
                    }
                }

                // Toque esquerda/direita + deslize horizontal para passar fotos e vídeos
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { goPrev() }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { goNext() }
                }
                .gesture(
                    DragGesture(minimumDistance: 35, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.width < -40 {
                                goNext()
                            } else if value.translation.width > 40 {
                                goPrev()
                            }
                        }
                )

                // HUD Superior estilo GTA Mission Passed
                VStack {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(Color(red: 0.2, green: 0.95, blue: 0.6))
                                Text("MISSION PASSED • \(item.eraTitle)")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(Color(red: 0.2, green: 0.95, blue: 0.6))
                            }
                            Text("\(item.date)  •  \(item.eraSubtitle)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.68))
                        .cornerRadius(14)

                        Spacer()

                        Text("\(currentIndex + 1) / \(memories.count)")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.black.opacity(0.68))
                            .cornerRadius(14)

                        Button(action: { isAutoPlaying.toggle() }) {
                            Image(systemName: isAutoPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.68))
                                .clipShape(Circle())
                        }

                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.68))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                    Spacer()
                }
            }
        }
        .onAppear {
            if !memories.isEmpty {
                currentIndex = min(max(0, initialIndex), memories.count - 1)
            }
        }
        .onReceive(timer) { _ in
            guard isAutoPlaying, !memories.isEmpty else { return }
            let current = memories[currentIndex]
            let isVideoPlaying = (current.videoResourceName != nil && current.videoExt?.lowercased() != "gif")
            if !isVideoPlaying {
                withAnimation {
                    currentIndex = (currentIndex + 1) % memories.count
                }
            }
        }
    }
}

// MARK: - Player Inline Autoplay + Miniatura de Cutscenes
struct InlineAutoplayVideoView: View {
    let url: URL
    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack {
            Color.black
            if let player {
                CleanVideoLayerView(player: player, videoGravity: .resizeAspect)
            }
        }
        .onAppear {
            let p = AVPlayer(url: url)
            p.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                p.seek(to: .zero)
                p.play()
            }
            p.play()
            self.player = p
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

struct CutsceneThumbnailView: View {
    let url: URL
    @State private var thumb: UIImage? = nil

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.09, blue: 0.16)
            if let thumb {
                Image(uiImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .onAppear {
            guard thumb == nil else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                let generated = Self.generateThumbnail(for: url)
                DispatchQueue.main.async {
                    self.thumb = generated
                }
            }
        }
    }

    private static func generateThumbnail(for url: URL) -> UIImage? {
        if url.pathExtension.lowercased() == "gif" {
            if let data = try? Data(contentsOf: url),
               let source = CGImageSourceCreateWithData(data as CFData, nil),
               let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                return UIImage(cgImage: cg)
            }
            return nil
        }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 360)
        if let cg = try? generator.copyCGImage(at: CMTime(seconds: 0.5, preferredTimescale: 600), actualTime: nil) {
            return UIImage(cgImage: cg)
        }
        return nil
    }
}

// MARK: - Visualizador de GIF Animado
struct AnimatedGIFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        if let data = try? Data(contentsOf: url),
           let source = CGImageSourceCreateWithData(data as CFData, nil) {
            let count = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var duration: Double = 0
            for i in 0..<count {
                if let cg = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cg))
                    duration += 0.18
                }
            }
            imageView.animationImages = images
            imageView.animationDuration = max(0.6, duration)
            imageView.startAnimating()
        }
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

struct GTAGIFModal: View {
    let gifURL: URL
    let title: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AnimatedGIFView(url: gifURL)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text(title.uppercased())
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.68))
                        .cornerRadius(12)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.68))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                Spacer()
            }
        }
    }
}
