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
class MediaManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var config: AppContentConfig
    @Published var fotos: [URL] = []
    @Published var videos: [URL] = []
    @Published var playlist: [URL] = []
    @Published var currentTrackIndex: Int = 0
    @Published var isMusicPlaying: Bool = false
    @Published var activeTab: Int = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var hasStartedIntroMusic: Bool = false
    private let introStartOffset: Double = 74.0 // 01:14 em Money For Nothing integral
    
    var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var jailbreakMediaDirectory: URL {
        URL(fileURLWithPath: "/var/mobile/Media/EnzoMemories")
    }
    
    var currentTrackName: String {
        guard !playlist.isEmpty, currentTrackIndex < playlist.count else { return "Sem música" }
        let name = playlist[currentTrackIndex].deletingPathExtension().lastPathComponent
        if name == "trilha" { return "Money For Nothing" }
        return name.replacingOccurrences(of: #"^ost_\d+_"#, with: "", options: .regularExpression)
    }
    
    override init() {
        self.config = AppContentConfig(
            titulo: "Enzo • IX",
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
        super.init()
        loadMediaFiles()
    }
    
    func loadMediaFiles() {
        var foundFotos: [URL] = []
        var foundVideos: [URL] = []
        var foundAudio: [URL] = []
        
        // Música principal integral no Bundle + faixas da OST embutidas
        if let bundledMusic = Bundle.main.url(forResource: "trilha", withExtension: "mp3") {
            foundAudio.append(bundledMusic)
        }
        if let bundleOSTs = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) {
            let sortedOSTs = bundleOSTs
                .filter { $0.deletingPathExtension().lastPathComponent.hasPrefix("ost_") }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            foundAudio.append(contentsOf: sortedOSTs)
        }
        
        // Pastas locais do usuário (Documents ou /var/mobile/Media/EnzoMemories)
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
                for item in items.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                    let ext = item.pathExtension.lowercased()
                    if ["jpg", "jpeg", "png", "heic"].contains(ext) {
                        foundFotos.append(item)
                    } else if ["mp4", "mov", "m4v"].contains(ext) {
                        foundVideos.append(item)
                    } else if ["mp3", "m4a", "aac", "wav"].contains(ext) {
                        foundAudio.append(item)
                    }
                }
            }
        }
        
        self.fotos = foundFotos
        self.videos = foundVideos
        self.playlist = foundAudio
        
        if audioPlayer == nil, let firstTrack = playlist.first {
            setupAudioPlayer(url: firstTrack)
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
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = playlist.count <= 1 ? -1 : 0
            audioPlayer?.prepareToPlay()
        } catch {
            print("Erro ao carregar música: \(error)")
        }
    }
    
    /// Inicia Money For Nothing integral em 01:14 (74.0s) com fade-in suave e continua sem cortes
    func startIntroMusic() {
        guard let player = audioPlayer else { return }
        if !hasStartedIntroMusic {
            hasStartedIntroMusic = true
            if player.duration > introStartOffset + 10.0 {
                player.currentTime = introStartOffset
            } else {
                player.currentTime = 0.0
            }
            player.volume = 0.04
            player.play()
            player.setVolume(0.88, fadeDuration: 5.5)
            isMusicPlaying = true
        } else if !player.isPlaying {
            player.play()
            isMusicPlaying = true
        }
    }
    
    /// Tempo decorrido desde o início da abertura (descontando os 74s iniciais da faixa integral)
    func currentIntroElapsed() -> Double? {
        guard let player = audioPlayer, player.isPlaying else { return nil }
        return max(0.0, player.currentTime - introStartOffset)
    }
    
    func toggleMusic() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isMusicPlaying = false
        } else {
            player.play()
            if player.volume < 0.2 {
                player.setVolume(0.88, fadeDuration: 1.5)
            }
            isMusicPlaying = true
        }
    }
    
    func nextTrack() {
        guard playlist.count > 1 else { return }
        currentTrackIndex = (currentTrackIndex + 1) % playlist.count
        setupAudioPlayer(url: playlist[currentTrackIndex])
        audioPlayer?.volume = 0.88
        audioPlayer?.play()
        isMusicPlaying = true
    }
    
    func startMusicIfAvailable() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        player.play()
        isMusicPlaying = true
    }
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if flag && playlist.count > 1 {
                nextTrack()
            }
        }
    }
}
