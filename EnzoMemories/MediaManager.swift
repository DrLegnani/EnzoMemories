import Foundation
import SwiftUI
import AVFoundation
import Combine

struct RecadoItem: Identifiable, Codable {
    var id: String { de }
    let de: String
    let relacao: String? // ex: "Pai & Mãe", "Vovó", "Amigo"
    let texto: String
    let videoFile: String? // nome do arquivo .mp4
    let fotoFile: String?  // nome do arquivo .jpg
}

struct AppContentConfig: Codable {
    let titulo: String
    let subtitulo: String
    let cartaPais: String
    let videoPaisFile: String?
    let musicaFundoFile: String?
    let recados: [RecadoItem]
}

@MainActor
class MediaManager: ObservableObject {
    @Published var config: AppContentConfig
    @Published var fotos: [URL] = []
    @Published var videos: [URL] = []
    @Published var isMusicPlaying: Bool = false
    @Published var activeTab: Int = 0
    
    private var audioPlayer: AVAudioPlayer?
    
    // Pasta principal de documentos
    var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Pasta alternativa via SSH / Jailbreak
    var jailbreakMediaDirectory: URL {
        URL(fileURLWithPath: "/var/mobile/Media/EnzoMemories")
    }
    
    init() {
        // Conteúdo inicial de exemplo / padrão
        self.config = AppContentConfig(
            titulo: "Para o Enzo",
            subtitulo: "Aula da Saudade • 9º Ano • Colégio Alfa • 2026",
            cartaPais: """
            Querido Enzo,
            
            Parece que foi ontem que você deu seus primeiros passos, com aquele sorriso curioso e os olhos brilhando para descobrir o mundo.
            
            Hoje você conclui uma etapa linda da sua vida: o 9º ano. Olhamos para você e vemos um menino inteligente, bem-humorado, cheio de talento e com um coração gigante.
            
            O Ensino Médio está chegando com novos desafios, mas saiba que você nunca estará sozinho. Nós temos um orgulho imenso de quem você é e de tudo o que ainda vai conquistar.
            
            Guarde com carinho os amigos que fez no Colégio Alfa e as histórias que viveu até aqui. Viva cada dia com intensidade, seja sempre leal aos seus valores e nunca tenha medo de sonhar alto.
            
            Com todo o nosso amor e orgulho do mundo,
            Seus Pais ❤️
            """,
            videoPaisFile: "video_pais.mp4",
            musicaFundoFile: "trilha.mp3",
            recados: [
                RecadoItem(de: "Pai e Mãe", relacao: "Família", texto: "Enzo, você é o nosso maior orgulho. Parabéns por essa conquista!", videoFile: "video_pais.mp4", fotoFile: nil),
                RecadoItem(de: "Família", relacao: "Coração", texto: "Voa alto, Enzo! Essa etapa é só o começo de muitas vitórias.", videoFile: nil, fotoFile: nil)
            ]
        )
        
        loadMediaFiles()
    }
    
    func loadMediaFiles() {
        var foundFotos: [URL] = []
        var foundVideos: [URL] = []
        
        // Pastas a inspecionar
        let directories = [documentsDirectory, jailbreakMediaDirectory]
        
        for dir in directories {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }
            
            // Verificar se existe conteudo.json
            let jsonURL = dir.appendingPathComponent("conteudo.json")
            if FileManager.default.fileExists(atPath: jsonURL.path),
               let data = try? Data(contentsOf: jsonURL),
               let decoded = try? JSONDecoder().decode(AppContentConfig.self, from: data) {
                self.config = decoded
            }
            
            // Listar fotos e vídeos
            if let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for item in items {
                    let ext = item.pathExtension.lowercased()
                    if ["jpg", "jpeg", "png", "heic"].contains(ext) {
                        foundFotos.append(item)
                    } else if ["mp4", "mov", "m4v"].contains(ext) {
                        foundVideos.append(item)
                    } else if ["mp3", "m4a", "aac"].contains(ext) && audioPlayer == nil {
                        setupAudioPlayer(url: item)
                    }
                }
            }
        }
        
        self.fotos = foundFotos
        self.videos = foundVideos
        
        // Se houver música configurada, inicializa
        if let musica = config.musicaFundoFile {
            let musicURL = documentsDirectory.appendingPathComponent(musica)
            if FileManager.default.fileExists(atPath: musicURL.path) {
                setupAudioPlayer(url: musicURL)
            }
        }
    }
    
    func resolveMediaURL(filename: String) -> URL? {
        let docURL = documentsDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: docURL.path) {
            return docURL
        }
        let jbURL = jailbreakMediaDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: jbURL.path) {
            return jbURL
        }
        return nil
    }
    
    private func setupAudioPlayer(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Toca em loop
            audioPlayer?.volume = 0.5
        } catch {
            print("Erro ao carregar música: \(error)")
        }
    }
    
    func toggleMusic() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isMusicPlaying = false
        } else {
            player.play()
            isMusicPlaying = true
        }
    }
    
    func startMusicIfAvailable() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        player.play()
        isMusicPlaying = true
    }
}
