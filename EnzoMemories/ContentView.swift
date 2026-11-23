import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var mediaManager = MediaManager()
    @State private var selectedTab = 0
    @State private var showLetter = false
    @State private var showSlideshow = false
    @State private var selectedVideoURL: URL? = nil
    @State private var selectedVideoTitle: String = "Vídeo"
    
    private let tabs = [
        ("Início", "sparkles"),
        ("Fotos", "photo.on.rectangle.angled"),
        ("Vídeos", "play.rectangle.fill"),
        ("Recados", "bubble.left.and.bubble.right.fill")
    ]
    
    var body: some View {
        ZStack {
            // Fundo escuro contemporâneo (Dark Glassmorphism)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.10),
                    Color(red: 0.09, green: 0.11, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header Superior
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(mediaManager.config.titulo.uppercased())
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("2026")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.40))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0.15))
                                .cornerRadius(8)
                        }
                        
                        Text(mediaManager.config.subtitulo)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(white: 0.65))
                    }
                    
                    Spacer()
                    
                    // Botão Música Ambiente
                    Button(action: { mediaManager.toggleMusic() }) {
                        HStack(spacing: 6) {
                            Image(systemName: mediaManager.isMusicPlaying ? "music.note" : "music.note.list")
                                .font(.system(size: 14))
                                .foregroundColor(mediaManager.isMusicPlaying ? Color(red: 0.95, green: 0.75, blue: 0.40) : .white)
                            Text(mediaManager.isMusicPlaying ? "Tocando Música" : "Música")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    }
                    
                    // Botão Atualizar Mídias
                    Button(action: { mediaManager.loadMediaFiles() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(9)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                
                // Seletor de Abas em Pílula
                HStack(spacing: 10) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        let tab = tabs[index]
                        let isSelected = selectedTab == index
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: tab.1)
                                    .font(.system(size: 14, weight: .medium))
                                Text(tab.0)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.white : Color.white.opacity(0.06))
                            .foregroundColor(isSelected ? Color.black : Color.white)
                            .cornerRadius(16)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                
                // Conteúdo da Aba Ativa
                ZStack {
                    switch selectedTab {
                    case 0:
                        HomeTab(mediaManager: mediaManager,
                                showLetter: $showLetter,
                                showSlideshow: $showSlideshow,
                                selectedVideoURL: $selectedVideoURL,
                                selectedVideoTitle: $selectedVideoTitle)
                    case 1:
                        PhotosTab(mediaManager: mediaManager, showSlideshow: $showSlideshow)
                    case 2:
                        VideosTab(mediaManager: mediaManager,
                                  selectedVideoURL: $selectedVideoURL,
                                  selectedVideoTitle: $selectedVideoTitle)
                    case 3:
                        RecadosTab(mediaManager: mediaManager)
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showLetter) {
            LetterReaderView(carta: mediaManager.config.cartaPais, mediaManager: mediaManager)
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
}

// Wrapper para URL identificável em modal
struct IdentifiableURL: Identifiable {
    var id: String { url.absoluteString }
    let url: URL
    let title: String
}

// MARK: - Aba Início
struct HomeTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var showLetter: Bool
    @Binding var showSlideshow: Bool
    @Binding var selectedVideoURL: URL?
    @Binding var selectedVideoTitle: String
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Banner Principal
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Uma surpresa especial para você", systemImage: "gift.fill")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.40))
                        Spacer()
                    }
                    
                    Text("Guarde para sempre as lembranças do seu 9º ano.")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Cada foto, recado e vídeo guardado aqui foi preparado com muito amor pelas pessoas que mais torcem pelo seu futuro.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.7))
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.18, blue: 0.25), Color(red: 0.10, green: 0.11, blue: 0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                // Cards de Destaque Lado a Lado
                HStack(spacing: 16) {
                    // Card da Carta dos Pais
                    Button(action: { showLetter = true }) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.40))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(white: 0.5))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("A Carta dos Pais")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Palavras que escrevemos do fundo do coração para você.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.65))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Text("Ler Carta ✉️")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .background(Color(red: 0.12, green: 0.13, blue: 0.18))
                        .cornerRadius(20)
                    }
                    
                    // Card do Vídeo dos Pais
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
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(white: 0.5))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vídeo dos Pais")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Uma mensagem que queríamos te falar olho no olho.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.65))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Text("Assistir Vídeo 🎬")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .background(Color(red: 0.12, green: 0.13, blue: 0.18))
                        .cornerRadius(20)
                    }
                }
                
                // Card de Slideshow da Linha do Tempo
                Button(action: { showSlideshow = true }) {
                    HStack(spacing: 16) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.95, green: 0.40, blue: 0.50))
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.95, green: 0.40, blue: 0.50).opacity(0.15))
                            .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Linha do Tempo em Fotos")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("\(mediaManager.fotos.count) fotos encontradas • Toque para iniciar a apresentação automática")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.65))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.12, green: 0.13, blue: 0.18))
                    .cornerRadius(20)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Aba Fotos
struct PhotosTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var showSlideshow: Bool
    
    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("\(mediaManager.fotos.count) Momentos Especiais")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showSlideshow = true }) {
                    Label("Iniciar Slideshow", systemImage: "play.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.95, green: 0.75, blue: 0.40))
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
            }
            .padding(.top, 8)
            
            if mediaManager.fotos.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(Color(white: 0.3))
                    Text("Nenhuma foto adicionada ainda")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                    Text("Copie fotos para a pasta do app no app Arquivos do iPad.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.4))
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

// MARK: - Aba Vídeos
struct VideosTab: View {
    @ObservedObject var mediaManager: MediaManager
    @Binding var selectedVideoURL: URL?
    @Binding var selectedVideoTitle: String
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recados e Mensagens em Vídeo")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            if mediaManager.videos.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "video.slash")
                        .font(.system(size: 50))
                        .foregroundColor(Color(white: 0.3))
                    Text("Nenhum vídeo adicionado ainda")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                    Text("Copie vídeos (.mp4 ou .mov) para a pasta do app.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.4))
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
                                        Color(red: 0.16, green: 0.17, blue: 0.22)
                                            .aspectRatio(16/9, contentMode: .fit)
                                            .cornerRadius(16)
                                        
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                    
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                .padding(12)
                                .background(Color(red: 0.11, green: 0.12, blue: 0.16))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Aba Recados
struct RecadosTab: View {
    @ObservedObject var mediaManager: MediaManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 340), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mural de Mensagens & Carinho")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(mediaManager.config.recados) { item in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(item.de)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                if let rel = item.relacao {
                                    Text(rel)
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                        .foregroundColor(Color(white: 0.7))
                                }
                            }
                            
                            Text(item.texto)
                                .font(.system(size: 14))
                                .lineSpacing(4)
                                .foregroundColor(Color(white: 0.85))
                        }
                        .padding(18)
                        .background(Color(red: 0.12, green: 0.13, blue: 0.18))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}
