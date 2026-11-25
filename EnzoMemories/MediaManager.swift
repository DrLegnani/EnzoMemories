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

struct MemoryPhotoItem: Identifiable, Codable, Hashable {
    let id: String
    let resourceName: String
    let date: String
    let year: Int
    let eraId: String
    let eraTitle: String
    let eraSubtitle: String
    let eraYears: String
    let videoResourceName: String?
    let videoExt: String?
}

struct MemoryEraGroup: Identifiable {
    var id: String { eraId }
    let eraId: String
    let eraTitle: String
    let eraSubtitle: String
    let eraYears: String
    let items: [MemoryPhotoItem]
    let startIndex: Int
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
    @Published var memories: [MemoryPhotoItem] = []
    @Published var memoryEras: [MemoryEraGroup] = []
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
            Para o nosso querido Enzo, 💙✨

            Se você está lendo estas palavras agora, é porque chegou a hora de abrir esta cápsula do tempo que preparamos com tanto carinho para você. ⏳💌 Antes de qualquer coisa: Mission Passed! Respect +. 🏆🔥 Parabéns por concluir o 9º ano e encerrar o Ensino Fundamental! 🎓🎉

            Enquanto reuníamos as fotos e os vídeos que você acabou de ver aqui no app, passou um filme inteiro na nossa cabeça. 🎬🥹 Parece que foi ontem que você era um menininho descobrindo o mundo, e de repente olhamos para o lado e vemos esse jovem incrível de 14 anos, pronto para dar um dos passos mais importantes da sua história. 🚀 O Ensino Fundamental foi uma campanha longa — teve fases tranquilas, alguns "chefões" difíceis nas provas 📚👾, risadas que vão ficar para sempre 😂 e amizades que ajudaram a moldar quem você é hoje. 🤝✨

            A gente sabe que, neste exato capítulo da sua vida, a sua mente está a mil com PCs, games e, claro, absolutamente tudo o que envolve GTA VI. 🖥️🎮🌴 Quando você abrir esta carta de novo daqui a alguns anos, provavelmente vai dar risada lembrando do quanto falava disso todos os dias! 😄 Mas queremos que você saiba que nós amamos ver esse brilho no seu olho. ✨ Essa sua paixão por tecnologia, a curiosidade de entender como as coisas funcionam e a vontade de explorar mundos novos dizem muito sobre a pessoa inteligente, criativa e dedicada que você é. 🧠💡⚡

            Agora, a tela de loading terminou e um mapa muito maior está se abrindo diante de você: o Ensino Médio. 🗺️🌟 As missões vão exigir um pouco mais de estratégia, o nível de dificuldade vai subir e as suas escolhas vão começar a desenhar o seu futuro. 🎯🧭 Mas pode ir sem medo, filho. Você já tem o melhor setup possível aí dentro: uma cabeça brilhante, um coração gigante ❤️ e uma família que acredita em você mais do que tudo. 🙌

            Onde quer que a vida te leve, nunca se esqueça de uma coisa: não importa o tamanho do mapa nem o quão difícil pareça a próxima fase, nós seremos sempre o seu ponto de save. 💾🏠 Sempre que precisar dar um pause ⏸️, recarregar as energias 🔋 ou simplesmente comemorar uma vitória 🏆, o nosso abraço estará aqui, esperando por você. 🤗 Nós somos o seu time fixo, jogando no modo co-op ao seu lado para o resto da vida. 🎮👨‍👩‍👦💜

            Curta muito essa conquista, celebre cada memória guardada aqui e siga em frente com coragem. 🥂✨ Temos um orgulho imenso de sermos seus pais e de acompanhar de perto o homem maravilhoso que você está se tornando. 🌟👏

            Nós te amamos infinitamente. ❤️🚀

            Com todo o nosso amor, Mãe e Pai... 🫶✨
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
        
        // Memórias (Mission Passed) embutidas via memories_manifest.json
        if let manifestURL = Bundle.main.url(forResource: "memories_manifest", withExtension: "json"),
           let data = try? Data(contentsOf: manifestURL),
           let decoded = try? JSONDecoder().decode([MemoryPhotoItem].self, from: data) {
            self.memories = decoded
            var groups: [MemoryEraGroup] = []
            for (idx, item) in decoded.enumerated() {
                if let last = groups.last, last.eraId == item.eraId {
                    var updated = last.items
                    updated.append(item)
                    groups[groups.count - 1] = MemoryEraGroup(
                        eraId: last.eraId,
                        eraTitle: last.eraTitle,
                        eraSubtitle: last.eraSubtitle,
                        eraYears: last.eraYears,
                        items: updated,
                        startIndex: last.startIndex
                    )
                } else {
                    groups.append(MemoryEraGroup(
                        eraId: item.eraId,
                        eraTitle: item.eraTitle,
                        eraSubtitle: item.eraSubtitle,
                        eraYears: item.eraYears,
                        items: [item],
                        startIndex: idx
                    ))
                }
            }
            self.memoryEras = groups
            for item in decoded {
                if let url = Bundle.main.url(forResource: item.resourceName, withExtension: "jpg") {
                    foundFotos.append(url)
                }
            }
        }
        
        // Fotos de grupo embutidas no Bundle (grupo_*.jpg)
        if let bundleFotos = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: nil) {
            let sortedGrupo = bundleFotos
                .filter { $0.deletingPathExtension().lastPathComponent.hasPrefix("grupo_") }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            foundFotos.append(contentsOf: sortedGrupo)
        }
        
        // Vídeos e GIFs embutidos no Bundle (clip_*)
        var bundledClips: [URL] = []
        for ext in ["mov", "mp4", "m4v", "gif"] {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                bundledClips.append(contentsOf: urls.filter {
                    $0.deletingPathExtension().lastPathComponent.hasPrefix("clip_")
                })
            }
        }
        foundVideos.append(contentsOf: bundledClips.sorted { $0.lastPathComponent < $1.lastPathComponent })
        
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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
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
    func startIntroMusic(forceRestart: Bool = false) {
        if forceRestart || !hasStartedIntroMusic {
            hasStartedIntroMusic = true
            if currentTrackIndex != 0 || audioPlayer == nil, let introTrack = playlist.first {
                currentTrackIndex = 0
                setupAudioPlayer(url: introTrack)
            }
            guard let player = audioPlayer else { return }
            if player.duration > introStartOffset + 10.0 {
                player.currentTime = introStartOffset
            } else {
                player.currentTime = 0.0
            }
            player.volume = 0.04
            player.play()
            player.setVolume(0.88, fadeDuration: 5.5)
            isMusicPlaying = true
        } else if let player = audioPlayer, !player.isPlaying {
            player.play()
            isMusicPlaying = true
        }
    }
    
    /// Tempo decorrido desde o início da abertura (descontando os 74s iniciais da faixa integral)
    func currentIntroElapsed() -> Double? {
        guard currentTrackIndex == 0, let player = audioPlayer, player.isPlaying else { return nil }
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

    func playTrack(matching query: String) {
        guard let idx = playlist.firstIndex(where: {
            $0.deletingPathExtension().lastPathComponent.localizedCaseInsensitiveContains(query)
        }) else { return }
        if currentTrackIndex == idx, let player = audioPlayer, player.isPlaying {
            return
        }
        currentTrackIndex = idx
        setupAudioPlayer(url: playlist[idx])
        audioPlayer?.volume = 0.0
        audioPlayer?.play()
        audioPlayer?.setVolume(0.90, fadeDuration: 1.5)
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
