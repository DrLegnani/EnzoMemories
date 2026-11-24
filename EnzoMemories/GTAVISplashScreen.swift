import SwiftUI
import AVFoundation

struct ExplosionPhotoItem: Identifiable {
    let id = UUID()
    let resourceName: String
    let angle: Double
    let distance: CGFloat
    let endRotation: Double
    let duration: Double
}

struct ExplodingPhotoCardView: View {
    let item: ExplosionPhotoItem
    @State private var animate = false
    
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: item.resourceName, withExtension: "jpg"),
               let img = UIImage(contentsOfFile: url.path) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 210, height: 250)
                    .clipped()
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.85), lineWidth: 2.5)
                    )
                    .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.4), radius: 18)
                    .scaleEffect(animate ? 1.95 : 0.08)
                    .rotationEffect(.degrees(animate ? item.endRotation : item.endRotation * 0.2))
                    .offset(
                        x: animate ? cos(item.angle) * item.distance : 0,
                        y: animate ? sin(item.angle) * (item.distance * 0.72) : 0
                    )
                    .opacity(animate ? 0.0 : 1.0)
                    .onAppear {
                        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: item.duration)) {
                            animate = true
                        }
                    }
            }
        }
    }
}

/// Player de vídeo sem controles visíveis (full-bleed, mutado para manter o Dire Straits limpo)
struct CleanVideoLayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerContainerUIView {
        let view = PlayerContainerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
    
    class PlayerContainerUIView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

struct GTAVISplashScreen: View {
    @Binding var isFinished: Bool
    @ObservedObject var mediaManager: MediaManager
    
    @State private var elapsed: Double = 0.0
    @State private var startDate: Date = Date()
    @State private var activeExplosions: [ExplosionPhotoItem] = []
    @State private var nextSpawnTime: Double = 0.0
    @State private var explosionCounter: Int = 0
    @State private var flashOpacity: Double = 0.0
    @State private var lastPhase: Int = 1
    @State private var heroZoom: CGFloat = 0.95
    @State private var heroIndex: Int = 1
    @State private var veoZoom: CGFloat = 1.0
    @State private var veoPlayer: AVPlayer? = nil
    @State private var tickTimer: Timer? = nil
    
    // 0..22.5s Explosão | 22.5..26.5s Guitarra Hero | 26.5..36.5s Vídeo Veo (10s) -> App aberto
    private let totalIntroDuration: Double = 36.5
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // FASE 1 (0.0s .. 22.5s): Explosão radial 3D das fotos das fases da vida
                if elapsed < 22.5 {
                    ZStack {
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.18, green: 0.05, blue: 0.24),
                                Color(red: 0.07, green: 0.02, blue: 0.11),
                                Color.black
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: geo.size.width * 0.7
                        )
                        .ignoresSafeArea()
                        
                        Circle()
                            .fill(Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.45))
                            .frame(width: 240, height: 240)
                            .blur(radius: 40)
                        
                        ForEach(activeExplosions) { item in
                            ExplodingPhotoCardView(item: item)
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // FASE 2 (22.5s .. 26.5s): Virada da guitarra -> Logo IX / ENZO centralizado (sem foto de terno)
                if elapsed >= 22.5 && elapsed < 26.5 {
                    ZStack {
                        if let bgImg = loadBundledImage(name: "gta_bg_\(heroIndex)", ext: "jpg") {
                            Image(uiImage: bgImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width * 1.08, height: geo.size.height * 1.08)
                                .clipped()
                                .ignoresSafeArea()
                        }
                        
                        RadialGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.25), Color.black.opacity(0.82)]),
                            center: .center,
                            startRadius: geo.size.width * 0.12,
                            endRadius: geo.size.width * 0.72
                        )
                        .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            // 6 estrelas prateadas (GTA VI)
                            HStack(spacing: 10) {
                                ForEach(0..<6, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.white, Color(red: 0.72, green: 0.78, blue: 0.86)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: Color.white.opacity(0.55), radius: 8)
                                }
                            }
                            
                            HStack(alignment: .center, spacing: 18) {
                                Text("IX")
                                    .font(.system(size: 155, weight: .black, design: .serif))
                                    .italic()
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 0.95, green: 0.85, blue: 0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.75), radius: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ENZO")
                                        .font(.system(size: 56, weight: .black, design: .rounded))
                                        .tracking(8)
                                        .foregroundColor(.white)
                                    Text("COLÉGIO ALFA • 2026")
                                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                        .tracking(4)
                                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                }
                            }
                        }
                        .scaleEffect(heroZoom)
                    }
                    .ignoresSafeArea()
                }
                
                // FASE 3 (26.5s .. 36.5s): Vídeo do Veo (Satélite 90° -> Enzo -> Celular abrindo o app)
                if elapsed >= 26.5, let player = veoPlayer {
                    CleanVideoLayerView(player: player)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(veoZoom)
                        .clipped()
                        .ignoresSafeArea()
                }
                
                // Flash de transição Rockstar
                Color.white
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // BARRA DE CARREGAMENTO OCUPANDO TODA A PARTE INFERIOR DA TELA (UI 100% LIMPA)
                VStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: geo.size.width, height: 10)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.95, blue: 1.0),
                                        Color(red: 1.0, green: 0.2, blue: 0.6),
                                        Color(red: 1.0, green: 0.5, blue: 0.15)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(min(1.0, elapsed / totalIntroDuration)), height: 10)
                            .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.9), radius: 10)
                    }
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            prepareVeoPlayer()
            startChoreography()
        }
        .onDisappear {
            tickTimer?.invalidate()
            tickTimer = nil
            veoPlayer?.pause()
        }
    }
    
    private func loadBundledImage(name: String, ext: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }
    
    private func prepareVeoPlayer() {
        if let url = Bundle.main.url(forResource: "veo_intro", withExtension: "mp4") {
            let p = AVPlayer(url: url)
            p.isMuted = true
            p.actionAtItemEnd = .pause
            veoPlayer = p
        }
    }
    
    private func triggerFlash(_ strength: Double = 0.8) {
        flashOpacity = strength
        withAnimation(.easeOut(duration: 0.25)) {
            flashOpacity = 0.0
        }
    }
    
    private func startChoreography() {
        startDate = Date()
        elapsed = 0.0
        nextSpawnTime = 0.0
        lastPhase = 1
        heroZoom = 0.95
        heroIndex = 1
        veoZoom = 1.0
        
        mediaManager.startIntroMusic()
        
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            Task { @MainActor in
                let t = mediaManager.currentPlaybackTime() ?? Date().timeIntervalSince(startDate)
                elapsed = t
                
                if t < 22.5 {
                    if t >= nextSpawnTime {
                        spawnExplosionPhoto(at: t)
                        let interval = t < 11.0 ? 1.25 : (t < 18.0 ? 0.85 : 0.50)
                        nextSpawnTime = t + interval
                    }
                } else if t >= 22.5 && t < 26.5 {
                    if lastPhase < 2 {
                        lastPhase = 2
                        activeExplosions.removeAll()
                        triggerFlash(0.9)
                        withAnimation(.easeOut(duration: 4.0)) {
                            heroZoom = 1.08
                        }
                    }
                } else if t >= 26.5 && t < totalIntroDuration {
                    if lastPhase < 3 {
                        lastPhase = 3
                        triggerFlash(0.55)
                        veoPlayer?.seek(to: .zero)
                        veoPlayer?.play()
                    }
                    // Zoom sutil nos últimos 0.6s para entrar suavemente na UI real do app
                    if t >= 35.8 && lastPhase == 3 {
                        lastPhase = 4
                        withAnimation(.easeIn(duration: 0.7)) {
                            veoZoom = 1.14
                        }
                    }
                } else if t >= totalIntroDuration {
                    tickTimer?.invalidate()
                    tickTimer = nil
                    veoPlayer?.pause()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isFinished = true
                    }
                }
            }
        }
    }
    
    private func spawnExplosionPhoto(at t: Double) {
        explosionCounter += 1
        let photoNum = ((explosionCounter - 1) % 16) + 1
        let resName = String(format: "explosion_%02d", photoNum)
        let angle = Double(explosionCounter) * 2.39996 + Double.random(in: -0.22...0.22)
        let dur = t > 14.0 ? 2.2 : 3.0
        
        let item = ExplosionPhotoItem(
            resourceName: resName,
            angle: angle,
            distance: 650,
            endRotation: Double.random(in: -14...14),
            duration: dur
        )
        activeExplosions.append(item)
        if activeExplosions.count > 12 {
            activeExplosions.removeFirst()
        }
    }
}
