import SwiftUI

struct GTASplashScene {
    let index: Int
    let alignRight: Bool
    let tag: String
    let title: String
    let subtitle: String
    let accentColor: Color
}

struct GTAVISplashScreen: View {
    @Binding var isFinished: Bool
    @ObservedObject var mediaManager: MediaManager
    
    @State private var currentSceneIdx: Int = 0
    @State private var bgPan: CGFloat = -28
    @State private var charPan: CGFloat = 36
    @State private var charScale: CGFloat = 0.94
    @State private var cardOpacity: Double = 0.0
    @State private var flashOpacity: Double = 0.0
    
    @State private var progress: CGFloat = 0.0
    @State private var showStartButton: Bool = false
    @State private var starsCount: Int = 1
    
    private let scenes: [GTASplashScene] = [
        GTASplashScene(
            index: 1,
            alignRight: true,
            tag: "PROTAGONISTA • CAPÍTULO IX",
            title: "THE BOSS: PRONTO PRO PRÓXIMO NÍVEL",
            subtitle: "O 9º Ano no Colégio Alfa foi concluído com respeito máximo. Novos territórios aguardam no Ensino Médio.",
            accentColor: Color(red: 0.0, green: 0.95, blue: 1.0)
        ),
        GTASplashScene(
            index: 2,
            alignRight: false,
            tag: "FAMÍLIA & ORIGENS • GOLDEN HOUR",
            title: "LEALDADE INCONDICIONAL",
            subtitle: "Não importa a missão ou a dificuldade da fase: sua família sempre será sua base e seu porto seguro.",
            accentColor: Color(red: 1.0, green: 0.84, blue: 0.25)
        ),
        GTASplashScene(
            index: 3,
            alignRight: true,
            tag: "ATITUDE & VISÃO • VICE VIBES",
            title: "SEMPRE AUTÊNTICO",
            subtitle: "Manter a calma, o bom humor e a visão de jogo é o segredo para dominar qualquer missão.",
            accentColor: Color(red: 1.0, green: 0.25, blue: 0.65)
        ),
        GTASplashScene(
            index: 4,
            alignRight: false,
            tag: "TRAJE DE GALA • FORMANDO 2026",
            title: "ESTILO PRÓPRIO: TERNO & SLIDE",
            subtitle: "Personalidade nível máximo desbloqueada: elegância de chefe com o conforto de quem domina o jogo.",
            accentColor: Color(red: 1.0, green: 0.55, blue: 0.2)
        ),
        GTASplashScene(
            index: 5,
            alignRight: true,
            tag: "CREW PRINCIPAL • AMOR INFINITO",
            title: "ORGULHO QUE NÃO CABE NO MAPA",
            subtitle: "Cada sorriso dessa jornada construiu quem você é hoje. Aperte Start para abrir sua cápsula do tempo.",
            accentColor: Color(red: 0.0, green: 0.95, blue: 1.0)
        )
    ]
    
    var body: some View {
        GeometryReader { geo in
            let scene = scenes[currentSceneIdx]
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 1. CAMADA DE FUNDO (BACKGROUND PARALLAX)
                if let bgImage = loadBundledImage(name: "gta_bg_\(scene.index)", ext: "jpg") {
                    Image(uiImage: bgImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 1.14, height: geo.size.height * 1.12)
                        .offset(x: bgPan, y: 0)
                        .clipped()
                        .ignoresSafeArea()
                }
                
                // Vinheta escura cinematográfica nas bordas
                RadialGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.65)]),
                    center: .center,
                    startRadius: geo.size.width * 0.2,
                    endRadius: geo.size.width * 0.75
                )
                .ignoresSafeArea()
                
                // 2. CAMADA DO PERSONAGEM RECORTADO (FOREGROUND 2.5D PARALLAX)
                HStack {
                    if scene.alignRight { Spacer() }
                    
                    if let charImage = loadBundledImage(name: "gta_char_\(scene.index)", ext: "png") {
                        Image(uiImage: charImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: geo.size.height * 0.90)
                            .scaleEffect(charScale, anchor: .bottom)
                            .offset(x: charPan, y: geo.size.height * 0.03)
                            .shadow(color: Color.black.opacity(0.75), radius: 22, x: 0, y: 8)
                    }
                    
                    if !scene.alignRight { Spacer() }
                }
                .padding(.horizontal, 40)
                .ignoresSafeArea()
                
                // 3. CARD DE HISTÓRIA & LOGO GTA (LADO OPOSTO AO PERSONAGEM)
                VStack {
                    // Barra Superior: Logo + Estrelas + Botão Pular
                    HStack(alignment: .center) {
                        HStack(spacing: 10) {
                            Text("VI")
                                .font(.system(size: 36, weight: .black, design: .serif))
                                .italic()
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 1.0, green: 0.55, blue: 0.2), Color(red: 0.95, green: 0.85, blue: 0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ENZO • VICE YEARS")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .tracking(3)
                                    .foregroundColor(.white)
                                Text("♪ DIRE STRAITS - MONEY FOR NOTHING")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(16)
                        
                        Spacer()
                        
                        // 5 Estrelas GTA
                        HStack(spacing: 6) {
                            ForEach(0..<5, id: \.self) { idx in
                                Image(systemName: idx < starsCount ? "star.fill" : "star")
                                    .font(.system(size: 15))
                                    .foregroundColor(idx < starsCount ? Color(red: 1.0, green: 0.85, blue: 0.2) : Color.white.opacity(0.25))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(16)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isFinished = true
                            }
                        }) {
                            HStack(spacing: 5) {
                                Text("PULAR INTRO")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(.white.opacity(0.85))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Card de Legenda da Cena (Alinhado no lado livre da tela)
                    HStack {
                        if !scene.alignRight { Spacer() }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(scene.tag)
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(scene.accentColor)
                            
                            Text(scene.title)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 4, x: 1, y: 2)
                            
                            Text(scene.subtitle)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.88))
                                .lineSpacing(4)
                        }
                        .padding(24)
                        .frame(maxWidth: geo.size.width * 0.48, alignment: .leading)
                        .background(Color.black.opacity(0.72))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(scene.accentColor.opacity(0.85), lineWidth: 2)
                        )
                        .opacity(cardOpacity)
                        
                        if scene.alignRight { Spacer() }
                    }
                    .padding(.horizontal, 36)
                    
                    Spacer()
                    
                    // HUD Inferior: Loading Bar PS5 / Botão Start
                    HStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(showStartButton ? "MODO HISTÓRIA PRONTO • COLÉGIO ALFA 2026" : "CARREGANDO MODO HISTÓRIA...")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .tracking(2)
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(scene.accentColor)
                            }
                            
                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.white.opacity(0.18))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 1.0, green: 0.6, blue: 0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: barGeo.size.width * progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        
                        if showStartButton {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    isFinished = true
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Text("ENTRAR NO JOGO")
                                        .font(.system(size: 15, weight: .black, design: .rounded))
                                        .tracking(2)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.15, blue: 0.55), Color(red: 1.0, green: 0.5, blue: 0.15)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(24)
                                .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.8), radius: 16, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.78))
                }
                
                // Flash branco sutil na troca de cena
                Color.white
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            mediaManager.startIntroMusicFrom125()
            startSceneAnimation(for: 0)
            startTimers()
        }
    }
    
    private func loadBundledImage(name: String, ext: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }
    
    private func startSceneAnimation(for idx: Int) {
        let alignRight = scenes[idx].alignRight
        bgPan = alignRight ? -26 : 26
        charPan = alignRight ? 38 : -38
        charScale = 0.94
        cardOpacity = 0.0
        flashOpacity = 0.35
        
        withAnimation(.easeOut(duration: 0.45)) {
            flashOpacity = 0.0
        }
        withAnimation(.easeOut(duration: 0.7)) {
            cardOpacity = 1.0
        }
        withAnimation(.linear(duration: 4.4)) {
            bgPan = alignRight ? 24 : -24
            charPan = alignRight ? -14 : 14
            charScale = 1.07
        }
    }
    
    private func startTimers() {
        // Troca de cenas a cada 4.4 segundos
        Timer.scheduledTimer(withTimeInterval: 4.4, repeats: true) { _ in
            let nextIdx = (currentSceneIdx + 1) % scenes.count
            currentSceneIdx = nextIdx
            if starsCount < 5 {
                starsCount += 1
            }
            startSceneAnimation(for: nextIdx)
        }
        
        // Barra de carregamento (completa em ~16 segundos, bem após o riff de guitarra entrar em 1:36!)
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if progress < 1.0 {
                progress = min(1.0, progress + 0.005)
            } else {
                timer.invalidate()
                withAnimation(.spring()) {
                    showStartButton = true
                }
            }
        }
    }
}
