import Foundation
import SwiftUI
import AVFoundation
import Combine

struct RecadoItem: Identifiable, Codable {
    var id: String { de }
    let de: String
    let relacao: String?
    let texto: String
    let videoFile: String?
    let fotoFile: String?
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
    private var hasStartedIntroMusic: Bool = false
    
    var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var jailbreakMediaDirectory: URL {
        URL(fileURLWithPath: "/var/mobile/Media/EnzoMemories")
    }
    
    init() {
        self.config = AppContentConfig(
            titulo: "Enzo • Vice Years",
            subtitulo: "Missão: 9º Ano Concluído • Colégio Alfa • 2026",
            cartaPais: """
            Querido Enzo,
            
            Parece que foi ontem que você deu seus primeiros passos, curioso e descobrindo cada canto desse mundo.
            
            Hoje você zera uma das fases mais importantes da sua história: o 9º ano. Olhamos para você e vemos um menino inteligente, parceiro, com um humor incrível e um coração gigante.
            
            O Ensino Médio é o próximo nível desbloqueado. Vão ter novos desafios e chefões mais difíceis, mas você tem tudo o que precisa para vencer. E o mais importante: a gente sempre vai ser sua equipe de suporte em qualquer fase.
            
            Guarde no peito os amigos de verdade que fez no Colégio Alfa, viva cada dia com sede de aprender e nunca deixe de ser esse menino autêntico e especial.
            
            Com todo o nosso amor e orgulho do mundo,
            Seus Pais ❤️
            """,
            videoPaisFile: "video_pais.mp4",
            musicaFundoFile: "trilha.mp3",
            recados: [
                RecadoItem(de: "Pai e Mãe", relacao: "Crew Principal", texto: "Enzo, você zerou o fundamental com maestria! Que venha o Ensino Médio. Amamos você além das estrelas!", videoFile: "video_pais.mp4", fotoFile: nil),
                RecadoItem(de: "Vovô e Vovó", relacao: "Família & Raízes", texto: "Enzo querido, como estamos orgulhosos de ver você crescer tão lindo e educado. Deus te abençoe sempre!", videoFile: nil, fotoFile: nil),
                RecadoItem(de: "Padrinhos", relacao: "Aliados de Honra", texto: "Respeito total, Enzo! Essa conquista é só o começo do seu império. Conta sempre com a gente!", videoFile: nil, fotoFile: nil)
            ]
        )
        
        loadMediaFiles()
    }
    
    func loadMediaFiles() {
        var foundFotos: [URL] = []
        var foundVideos: [URL] = []
        
        // 1. Carregar fotos embutidas no Bundle (enzo_photo_1.jpg .. enzo_photo_5.jpg)
        for i in 1...5 {
            if let bundledURL = Bundle.main.url(forResource: "enzo_photo_\(i)", withExtension: "jpg") {
                foundFotos.append(bundledURL)
            }
        }
        
        // 2. Inspecionar pastas locais do iPad (Documents e /var/mobile/Media/EnzoMemories)
        let directories = [documentsDirectory, jailbreakMediaDirectory]
        
        for dir in directories {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }
            
            let jsonURL = dir.appendingPathComponent("conteudo.json")
            if FileManager.default.fileExists(atPath: jsonURL.path),
               let data = try? Data(contentsOf: jsonURL),
               let decoded = try? JSONDecoder().decode(AppContentConfig.self, from: data) {
                self.config = decoded
            }
            
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
        
        // 3. Configurar trilha sonora (Money For Nothing embutida no Bundle ou na pasta)
        if audioPlayer == nil {
            if let musica = config.musicaFundoFile,
               let extURL = resolveMediaURL(filename: musica) {
                setupAudioPlayer(url: extURL)
            } else if let bundledMusic = Bundle.main.url(forResource: "trilha", withExtension: "mp3") {
                setupAudioPlayer(url: bundledMusic)
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
        let nameOnly = (filename as NSString).deletingPathExtension
        let extOnly = (filename as NSString).pathExtension
        if let bundleURL = Bundle.main.url(forResource: nameOnly, withExtension: extOnly.isEmpty ? nil : extOnly) {
            return bundleURL
        }
        return nil
    }
    
    private func setupAudioPlayer(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
        } catch {
            print("Erro ao carregar música: \(error)")
        }
    }
    
    /// Inicia Money For Nothing em 1:25 (85s) com fade-in suave de 6 segundos e continua tocando na UI
    func startIntroMusicFrom125() {
        guard let player = audioPlayer else { return }
        if !hasStartedIntroMusic {
            hasStartedIntroMusic = true
            // Se a música tiver mais de 90 segundos, começa em 1:25 (85.0s)
            if player.duration > 90.0 {
                player.currentTime = 85.0
            }
            player.volume = 0.0
            player.play()
            player.setVolume(0.85, fadeDuration: 6.0)
            isMusicPlaying = true
        } else if !player.isPlaying {
            player.play()
            isMusicPlaying = true
        }
    }
    
    func toggleMusic() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isMusicPlaying = false
        } else {
            player.play()
            if player.volume < 0.2 {
                player.setVolume(0.85, fadeDuration: 1.5)
            }
            isMusicPlaying = true
        }
    }
    
    func startMusicIfAvailable() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        player.play()
        isMusicPlaying = true
    }
}
