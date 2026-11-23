import SwiftUI
import AVKit

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
    @State private var droneScale: CGFloat = 1.0
    @State private var droneStep: Int = 0
    @State private var heroZoom: CGFloat = 0.95
    @State private var heroIndex: Int = 1
    @State private var phoneYOffset: CGFloat = 220
    @State private var phoneScale: CGFloat = 0.42
    @State private var tickTimer: Timer? = nil
    
    private let totalIntroDuration: Double = 34.0
    
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
                
                // FASE 2 (22.5s .. 27.5s): Virada da guitarra -> Logo GTA VI + Retrato Realista do Enzo
                if elapsed >= 22.5 && elapsed < 27.5 {
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
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.75)]),
                            center: UnitPoint(x: 0.65, y: 0.5),
                            startRadius: geo.size.width * 0.15,
                            endRadius: geo.size.width * 0.75
                        )
                        .ignoresSafeArea()
                        
                        HStack {
                            // Logo GTA VI em destaque
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .center, spacing: 14) {
                                    Text("VI")
                                        .font(.system(size: 130, weight: .black, design: .serif))
                                        .italic()
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 0.95, green: 0.85, blue: 0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.75), radius: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("ENZO")
                                            .font(.system(size: 46, weight: .black, design: .rounded))
                                            .tracking(7)
                                            .foregroundColor(.white)
                                        Text("COLÉGIO ALFA • 2026")
                                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                            .tracking(3)
                                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                    }
                                }
                            }
                            .padding(.leading, 44)
                            
                            Spacer()
                            
                            // Retrato realista detalhado do Enzo
                            if let heroImg = loadBundledImage(name: "enzo_hero_\(heroIndex)", ext: "png") {
                                Image(uiImage: heroImg)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: geo.size.height * 0.92)
                                    .scaleEffect(heroZoom, anchor: .bottom)
                                    .shadow(color: .black.opacity(0.85), radius: 24)
                                    .padding(.trailing, 32)
                            }
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // FASE 3A (27.5s .. 30.5s): Drone Satélite 90º estilo GTA V
                if elapsed >= 27.5 && elapsed < 30.5 {
                    ZStack {
                        if let mapImg = loadBundledImage(name: "drone_map_90", ext: "jpg") {
                            Image(uiImage: mapImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .scaleEffect(droneScale)
                                .clipped()
                                .ignoresSafeArea()
                        }
                        
                        Circle()
                            .stroke(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.8), lineWidth: 2)
                            .frame(width: 90, height: 90)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.2, blue: 0.6))
                            .frame(width: 12, height: 12)
                    }
                    .ignoresSafeArea()
                }
                
                // FASE 3B (30.5s .. 34.0s): Personagem erguendo o celular + Zoom na UI do App
                if elapsed >= 30.5 {
                    ZStack {
                        if let bgStreet = loadBundledImage(name: "gta_bg_3", ext: "jpg") {
                            Image(uiImage: bgStreet)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width * 1.1, height: geo.size.height * 1.1)
                                .blur(radius: 5)
                                .brightness(-0.18)
                                .ignoresSafeArea()
                        }
                        
                        HStack {
                            if let heroStreet = loadBundledImage(name: "enzo_hero_3", ext: "png") {
                                Image(uiImage: heroStreet)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: geo.size.height * 0.88)
                                    .blur(radius: 1.5)
                                    .padding(.leading, 24)
                            }
                            Spacer()
                        }
                        
                        // Aparelho sendo erguido com a miniatura viva da UI e dando zoom
                        VStack(spacing: 12) {
                            HStack {
                                Text("VI")
                                    .font(.system(size: 26, weight: .black, design: .serif))
                                    .italic()
                                    .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                                Text("ENZO • MEMORIES")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("RESPECT +")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("LEVEL UNLOCKED: ENSINO MÉDIO")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                Text("MISSION PASSED: O 9º ANO É SEU!")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(Color(red: 0.22, green: 0.08, blue: 0.25))
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.6), lineWidth: 1.5))
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Image(systemName: "envelope.badge.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.6))
                                    Spacer()
                                    Text("A Carta dos Pais")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .background(Color(red: 0.12, green: 0.08, blue: 0.18))
                                .cornerRadius(16)
                                
                                VStack(alignment: .leading) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                    Spacer()
                                    Text("Vídeo dos Pais")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .background(Color(red: 0.08, green: 0.12, blue: 0.18))
                                .cornerRadius(16)
                            }
                        }
                        .padding(24)
                        .frame(width: geo.size.width * 0.72, height: geo.size.height * 0.72)
                        .background(Color(red: 0.06, green: 0.05, blue: 0.09))
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.28), lineWidth: 4)
                        )
                        .shadow(color: .black.opacity(0.9), radius: 40)
                        .offset(y: phoneYOffset)
                        .scaleEffect(phoneScale)
                    }
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
            startChoreography()
        }
        .onDisappear {
            tickTimer?.invalidate()
            tickTimer = nil
        }
    }
    
    private func loadBundledImage(name: String, ext: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
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
        droneStep = 0
        droneScale = 1.0
        heroZoom = 0.95
        heroIndex = 1
        phoneYOffset = 220
        phoneScale = 0.42
        
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
                } else if t >= 22.5 && t < 27.5 {
                    if lastPhase < 2 {
                        lastPhase = 2
                        activeExplosions.removeAll()
                        triggerFlash(0.9)
                        withAnimation(.easeOut(duration: 4.5)) {
                            heroZoom = 1.08
                        }
                    }
                    if t >= 25.2 && heroIndex == 1 {
                        heroIndex = 2
                        triggerFlash(0.45)
                    }
                } else if t >= 27.5 && t < 30.5 {
                    if lastPhase < 3 {
                        lastPhase = 3
                        triggerFlash(0.6)
                    }
                    if t >= 27.6 && droneStep == 0 {
                        droneStep = 1
                        withAnimation(.easeOut(duration: 0.65)) { droneScale = 1.65 }
                    } else if t >= 28.6 && droneStep == 1 {
                        droneStep = 2
                        triggerFlash(0.3)
                        withAnimation(.easeOut(duration: 0.65)) { droneScale = 2.8 }
                    } else if t >= 29.6 && droneStep == 2 {
                        droneStep = 3
                        triggerFlash(0.35)
                        withAnimation(.easeOut(duration: 0.65)) { droneScale = 4.6 }
                    }
                } else if t >= 30.5 && t < totalIntroDuration {
                    if lastPhase < 4 {
                        lastPhase = 4
                        triggerFlash(0.55)
                        withAnimation(.easeOut(duration: 1.1)) {
                            phoneYOffset = 0
                            phoneScale = 0.68
                        }
                    }
                    if t >= 32.3 && lastPhase == 4 {
                        lastPhase = 5
                        withAnimation(.easeInOut(duration: 1.5)) {
                            phoneScale = 1.42
                        }
                    }
                } else if t >= totalIntroDuration {
                    tickTimer?.invalidate()
                    tickTimer = nil
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
