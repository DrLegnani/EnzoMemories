import SwiftUI

struct GTAVISplashScreen: View {
    @Binding var isFinished: Bool
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 30
    @State private var progress: CGFloat = 0.0
    @State private var showStartButton: Bool = false
    @State private var starsCount: Int = 0
    
    var body: some View {
        ZStack {
            // Fundo Pôr do Sol Neon Vice City
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.04, blue: 0.18), // Roxo profundo
                    Color(red: 0.28, green: 0.05, blue: 0.25), // Magenta escuro
                    Color(red: 0.05, green: 0.06, blue: 0.12)  // Preto base
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Grid de linhas de horizonte retrô neon
            VStack {
                Spacer()
                RetroSunAndGrid()
                    .frame(height: 240)
                    .opacity(0.4)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Nível de Procurado / Respeito (Easter egg GTA)
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < starsCount ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(index < starsCount ? Color(red: 1.0, green: 0.85, blue: 0.2) : Color.white.opacity(0.2))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
                
                // LOGOTIPO ESTILO GTA VI
                ZStack {
                    // O grande "VI" romano em gradiente neon
                    Text("VI")
                        .font(.system(size: 140, weight: .black, design: .serif))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.2, blue: 0.6), // Pink neon
                                    Color(red: 1.0, green: 0.5, blue: 0.2), // Laranja pôr do sol
                                    Color(red: 0.95, green: 0.85, blue: 0.3) // Dourado
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.7), radius: 25, x: 0, y: 0)
                        .scaleEffect(logoScale)
                    
                    // Texto "ENZO" atravessando com estética Vice City
                    VStack(spacing: 2) {
                        Text("ENZO")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 4, x: 2, y: 3)
                        
                        Text("VICE YEARS • 2012 - 2026")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .tracking(5)
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0)) // Azul neon ciano
                            .shadow(color: Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.6), radius: 10)
                    }
                    .offset(y: textOffset)
                }
                .opacity(logoOpacity)
                
                Spacer()
                
                // Barra de carregamento estilo Rockstar Games
                VStack(spacing: 12) {
                    if !showStartButton {
                        HStack {
                            Text("CARREGANDO MEMÓRIAS...")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(Color.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.7))
                        }
                        .padding(.horizontal, 40)
                        
                        // Barra
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 1.0, green: 0.2, blue: 0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progress, height: 8)
                                    .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.6), radius: 8)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 40)
                    } else {
                        // Botão de Entrada estilo GTA
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isFinished = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text("ENTRAR NO JOGO")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .tracking(3)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 38)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.15, blue: 0.55), Color(red: 1.0, green: 0.45, blue: 0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30)
                            .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.7), radius: 20, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                            )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Text("COLÉGIO ALFA • TURMA DO 9º ANO")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(3)
                        .foregroundColor(Color.white.opacity(0.4))
                        .padding(.top, 8)
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            animateSplash()
        }
    }
    
    private func animateSplash() {
        // Animação do logo
        withAnimation(.easeOut(duration: 1.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
            textOffset = 15
        }
        
        // Estrelas acendendo
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            if starsCount < 5 {
                withAnimation { starsCount += 1 }
            } else {
                timer.invalidate()
            }
        }
        
        // Barra de progresso enchendo
        Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.02
            } else {
                timer.invalidate()
                withAnimation(.spring()) {
                    showStartButton = true
                }
            }
        }
    }
}

// Elemento visual de pôr do sol e grade retrô
struct RetroSunAndGrid: View {
    var body: some View {
        ZStack {
            // Sol poente em fatias
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 1.0, green: 0.2, blue: 0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 180, height: 180)
                .offset(y: 40)
            
            // Grade de perspectiva
            GeometryReader { geo in
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    let centerX = width / 2
                    
                    // Linhas convergentes
                    for i in -6...6 {
                        let x = centerX + CGFloat(i) * (width / 10)
                        path.move(to: CGPoint(x: centerX, y: height * 0.4))
                        path.addLine(to: CGPoint(x: x * 1.5 - centerX * 0.5, y: height))
                    }
                    
                    // Linhas horizontais
                    for j in 1...6 {
                        let y = height * 0.4 + pow(CGFloat(j) / 6.0, 2) * (height * 0.6)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.35), lineWidth: 1)
            }
        }
    }
}
