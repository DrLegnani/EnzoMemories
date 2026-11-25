import SwiftUI
import AVFoundation
import ImageIO

final class ExplosionImageCache {
    static let shared = ExplosionImageCache()
    private var cache: [String: UIImage] = [:]
    private let lock = NSLock()

    func image(for resourceName: String) -> UIImage? {
        lock.lock()
        if let existing = cache[resourceName] {
            lock.unlock()
            return existing
        }
        lock.unlock()

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "jpg") else { return nil }
        let img = Self.downsampledImage(at: url, maxPixelSize: 640) ?? UIImage(contentsOfFile: url.path)
        if let img {
            lock.lock()
            cache[resourceName] = img
            lock.unlock()
        }
        return img
    }

    func preloadAll() {
        for i in 1...20 {
            _ = image(for: String(format: "intro_%02d", i))
        }
    }

    private static func downsampledImage(at url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct IntroMilestoneItem: Identifiable {
    let id = UUID()
    let index: Int
    let resourceName: String
    let caption: String
    let isVideo: Bool
    let targetX: CGFloat
    let targetY: CGFloat
    let rotation: Double
}

struct ExplodingPolaroidItem: Identifiable {
    let id = UUID()
    let resourceName: String
    let angle: Double
    let distance: CGFloat
    let endRotation: Double
}

/// Player de vídeo sem controles visíveis (aspecto original preservado quando resizeAspect, ou full-bleed)
struct CleanVideoLayerView: UIViewRepresentable {
    let player: AVPlayer
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    
    func makeUIView(context: Context) -> PlayerContainerUIView {
        let view = PlayerContainerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = videoGravity
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = videoGravity
    }
    
    class PlayerContainerUIView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

/// Polaroid na sequência cronológica: mantém proporção original sem texto na borda
struct SequencePolaroidCardView: View {
    let item: IntroMilestoneItem
    let usgPlayer: AVPlayer?
    @State private var appeared = false

    var body: some View {
        Group {
            if item.isVideo, let player = usgPlayer {
                CleanVideoLayerView(player: player, videoGravity: .resizeAspect)
                    .frame(width: 380, height: 215)
                    .background(Color.black)
                    .cornerRadius(4)
            } else if let img = ExplosionImageCache.shared.image(for: item.resourceName) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 330, maxHeight: 300)
                    .cornerRadius(4)
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, 10)
        .padding(.bottom, 26)
        .background(Color(white: 0.97))
        .cornerRadius(9)
        .shadow(color: Color.black.opacity(0.48), radius: 14, x: 0, y: 7)
        .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.28), radius: 12)
        .scaleEffect(appeared ? (item.isVideo ? 1.08 : 1.0) : 0.32)
        .rotationEffect(.degrees(appeared ? item.rotation : 0))
        .offset(x: appeared ? item.targetX : 0, y: appeared ? item.targetY : 0)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.95)) {
                appeared = true
            }
        }
    }
}

/// Polaroid na explosão final (22.5s): todas as 20 fotos estouram juntas revelando o logo
struct BurstPolaroidCardView: View {
    let item: ExplodingPolaroidItem
    @State private var burst = false

    var body: some View {
        Group {
            if let img = ExplosionImageCache.shared.image(for: item.resourceName) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 190, maxHeight: 190)
                    .cornerRadius(4)
                    .padding(7)
                    .background(Color(white: 0.97))
                    .cornerRadius(7)
                    .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.35), radius: 8)
                    .scaleEffect(burst ? 1.45 : 0.18)
                    .rotationEffect(.degrees(burst ? item.endRotation : 0))
                    .offset(
                        x: burst ? cos(item.angle) * item.distance : 0,
                        y: burst ? sin(item.angle) * (item.distance * 0.72) : 0
                    )
                    .opacity(burst ? 0.0 : 1.0)
                    .onAppear {
                        withAnimation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 1.35)) {
                            burst = true
                        }
                    }
            }
        }
    }
}

struct GTAVISplashScreen: View {
    @Binding var isFinished: Bool
    @ObservedObject var mediaManager: MediaManager
    
    @State private var elapsed: Double = 0.0
    @State private var startDate: Date = Date()
    @State private var shownItems: [IntroMilestoneItem] = []
    @State private var burstItems: [ExplodingPolaroidItem] = []
    @State private var spawnedCount: Int = 0
    @State private var flashOpacity: Double = 0.0
    @State private var lastPhase: Int = 1
    @State private var heroZoom: CGFloat = 0.94
    @State private var veoZoom: CGFloat = 1.0
    @State private var usgPlayer: AVPlayer? = nil
    @State private var veoPlayer: AVPlayer? = nil
    @State private var tickTimer: Timer? = nil
    
    // 0..22.5s Sequência Cronológica (20 itens únicos) | 22.5..26.5s Explosão + Logo IX/ENZO maior | 26.5..36.5s Vídeo Veo
    private let totalIntroDuration: Double = 36.5
    
    private static let milestones: [(String, String, Bool)] = [
        ("intro_01", "2012 • Ultrassom", true),
        ("intro_02", "2012 • Maternidade", false),
        ("intro_03", "2012 • Primeiros Dias", false),
        ("intro_04", "2013 • Golden Gate", false),
        ("intro_05", "2013 • Cestinho", false),
        ("intro_06", "2014 • Sorrindo ao Sol", false),
        ("intro_07", "2015 • Praia", false),
        ("intro_08", "2017 • Parque", false),
        ("intro_09", "2017 • Beca Amarela", false),
        ("intro_10", "2018 • Paris", false),
        ("intro_11", "2018 • Judô 1º Lugar", false),
        ("intro_12", "2018 • Glacier Palace", false),
        ("intro_13", "2020 • Bike", false),
        ("intro_14", "2021 • Família", false),
        ("intro_15", "2022 • Universal", false),
        ("intro_16", "2022 • Miami Praia", false),
        ("intro_17", "2025 • Viagem EUA", false),
        ("intro_18", "2025 • Nova York", false),
        ("intro_19", "2026 • Família", false),
        ("intro_20", "2026 • Formatura 9º Ano", false)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // FASE 1 (0.0s .. 22.5s): 20 memórias únicas em Polaroid (proporção original, sem repetição)
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
                            .frame(width: 260, height: 260)
                            .blur(radius: 40)
                        
                        ForEach(shownItems) { item in
                            SequencePolaroidCardView(item: item, usgPlayer: usgPlayer)
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // FASE 2 (22.5s .. 26.5s): Explosão de todas as 20 fotos + Logo IX / ENZO maior sobre fundo saturado
                if elapsed >= 22.5 && elapsed < 26.5 {
                    ZStack {
                        if let bgImg = loadBundledImage(name: "gta_bg_1", ext: "jpg") {
                            Image(uiImage: bgImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width * 1.06, height: geo.size.height * 1.06)
                                .clipped()
                                .ignoresSafeArea()
                        }
                        
                        RadialGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.58), Color.black.opacity(0.76)]),
                            center: .center,
                            startRadius: geo.size.width * 0.10,
                            endRadius: geo.size.width * 0.72
                        )
                        .ignoresSafeArea()
                        
                        ForEach(burstItems) { bItem in
                            BurstPolaroidCardView(item: bItem)
                        }
                        
                        VStack(spacing: 14) {
                            // 6 estrelas prateadas (GTA VI)
                            HStack(spacing: 12) {
                                ForEach(0..<6, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.white, Color(red: 0.72, green: 0.78, blue: 0.86)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: Color.black.opacity(0.9), radius: 6)
                                        .shadow(color: Color.white.opacity(0.65), radius: 10)
                                }
                            }
                            
                            HStack(alignment: .center, spacing: 22) {
                                Text("IX")
                                    .font(.system(size: 195, weight: .black, design: .serif))
                                    .italic()
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 0.98, green: 0.88, blue: 0.35)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.95), radius: 12, x: 0, y: 4)
                                    .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.8), radius: 26)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ENZO")
                                        .font(.system(size: 78, weight: .black, design: .rounded))
                                        .tracking(10)
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.95), radius: 10, x: 0, y: 4)
                                    Text("COLÉGIO ALFA • 2026")
                                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                        .tracking(5)
                                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                        .shadow(color: Color.black.opacity(0.95), radius: 8, x: 0, y: 2)
                                }
                            }
                        }
                        .scaleEffect(heroZoom)
                    }
                    .ignoresSafeArea()
                }
                
                // FASE 3 (26.5s .. 36.5s): Vídeo do Veo (sem áudio para não oscilar volume da música)
                if elapsed >= 26.5, let player = veoPlayer {
                    CleanVideoLayerView(player: player, videoGravity: .resizeAspectFill)
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
                
                // BARRA DE CARREGAMENTO OCUPANDO TODA A PARTE INFERIOR DA TELA
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
            DispatchQueue.global(qos: .userInitiated).async {
                ExplosionImageCache.shared.preloadAll()
            }
            preparePlayers()
            startChoreography()
        }
        .onDisappear {
            tickTimer?.invalidate()
            tickTimer = nil
            usgPlayer?.pause()
            usgPlayer = nil
            veoPlayer?.pause()
            veoPlayer = nil
            shownItems.removeAll()
            burstItems.removeAll()
        }
    }
    
    private func loadBundledImage(name: String, ext: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }
    
    /// Cria AVPlayer exclusivamente com faixa de vídeo (sem faixa de áudio) para nunca reduzir o volume do AVAudioPlayer
    private func makeVideoOnlyPlayer(url: URL) -> AVPlayer {
        let asset = AVURLAsset(url: url)
        let composition = AVMutableComposition()
        if let videoTrack = asset.tracks(withMediaType: .video).first,
           let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            compTrack.preferredTransform = videoTrack.preferredTransform
            let player = AVPlayer(playerItem: AVPlayerItem(asset: composition))
            player.isMuted = true
            player.volume = 0.0
            player.actionAtItemEnd = .pause
            return player
        }
        let fallback = AVPlayer(url: url)
        fallback.isMuted = true
        fallback.volume = 0.0
        fallback.actionAtItemEnd = .pause
        return fallback
    }
    
    private func preparePlayers() {
        if let usgURL = Bundle.main.url(forResource: "clip_01_Ultrassom (2012)", withExtension: "mov") {
            usgPlayer = makeVideoOnlyPlayer(url: usgURL)
        }
        if let veoURL = Bundle.main.url(forResource: "veo_intro", withExtension: "mp4") {
            veoPlayer = makeVideoOnlyPlayer(url: veoURL)
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
        spawnedCount = 0
        shownItems.removeAll()
        burstItems.removeAll()
        lastPhase = 1
        heroZoom = 0.94
        veoZoom = 1.0
        
        mediaManager.startIntroMusic(forceRestart: true)
        usgPlayer?.seek(to: .zero)
        usgPlayer?.play()
        
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            Task { @MainActor in
                let t = mediaManager.currentIntroElapsed() ?? Date().timeIntervalSince(startDate)
                elapsed = t
                
                if t < 22.5 {
                    // Item #1 (ultrassom vídeo) fica 2.5s no início; itens #2..#20 entram sequencialmente sem repetição
                    var targetCount = 1
                    if t >= 2.5 {
                        targetCount = min(Self.milestones.count, 1 + Int(((t - 2.5) / 20.0) * Double(Self.milestones.count - 1)) + 1)
                    }
                    while spawnedCount < targetCount {
                        spawnMilestone(at: spawnedCount)
                        spawnedCount += 1
                    }
                } else if t >= 22.5 && t < 26.5 {
                    if lastPhase < 2 {
                        lastPhase = 2
                        usgPlayer?.pause()
                        shownItems.removeAll()
                        triggerFlash(0.9)
                        spawnFinalExplosion()
                        withAnimation(.easeOut(duration: 4.0)) {
                            heroZoom = 1.08
                        }
                    }
                } else if t >= 26.5 && t < totalIntroDuration {
                    if lastPhase < 3 {
                        lastPhase = 3
                        burstItems.removeAll()
                        triggerFlash(0.55)
                        veoPlayer?.seek(to: .zero)
                        veoPlayer?.play()
                    }
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
    
    private func spawnMilestone(at index: Int) {
        guard index < Self.milestones.count else { return }
        let m = Self.milestones[index]
        let isFirst = (index == 0)
        let angle = Double(index) * 2.39996
        let tx: CGFloat = isFirst ? 0 : CGFloat(cos(angle) * 285.0)
        let ty: CGFloat = isFirst ? 0 : CGFloat(sin(angle) * 115.0)
        let sign: Double = (index % 2 == 0) ? 1.0 : -1.0
        let mag: Double = 4.0 + Double(index % 5) * 2.5
        let rot: Double = isFirst ? 0.0 : sign * mag
        
        let item = IntroMilestoneItem(
            index: index + 1,
            resourceName: m.0,
            caption: m.1,
            isVideo: m.2,
            targetX: tx,
            targetY: ty,
            rotation: rot
        )
        shownItems.append(item)
        if shownItems.count > 13 {
            shownItems.removeFirst()
        }
    }
    
    private func spawnFinalExplosion() {
        burstItems = Self.milestones.enumerated().map { idx, m in
            let angle = (Double(idx) / Double(Self.milestones.count)) * Double.pi * 2.0
            let dist: CGFloat = 580 + CGFloat((idx % 3) * 110)
            let rot: Double = (idx % 2 == 0 ? 1.0 : -1.0) * Double(16 + (idx % 4) * 7)
            return ExplodingPolaroidItem(
                resourceName: m.0,
                angle: angle,
                distance: dist,
                endRotation: rot
            )
        }
    }
}
