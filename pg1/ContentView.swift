//
//  ContentView.swift
//  pg1
//
//  Created by Farid Sakhizad on 07.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = LibraryVM()
    @StateObject private var player = AudioPlayer()
    
    @State private var showingImporter = false
    @State private var importError: String?
    
    @State private var trackIndex: Int = 0
   
    var body: some View {
        HStack {
            if let track = vm.selected {
                Text("Track index: \(trackIndex) | Tqack Name \(track.fileName)")
                    .font(.headline)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            } else {
                Text("Трек не выбран")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        NavigationStack {
            VStack {
                List {
                    ForEach(vm.tracks.indices, id: \.self) { index in
                        let track = vm.tracks[index]

                        HStack {
                            Image(systemName: vm.selected == track ? "music.note.list" : "music.note")

                            Text("\(index + 1)")
                                .frame(width: 24, alignment: .trailing)

                            Spacer().frame(width: 8)

                            Text(track.fileName)
                                .lineLimit(1)

                            Spacer()

                            if vm.selected == track {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            trackIndex = index

                            vm.select(track)
                        }
                    }
                }

                VStack(spacing: 8) {
                    HStack {
                        Text(formatTime(player.currentTime))
                        Spacer()
                        Text(formatTime(player.duration))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if (trackIndex - 1 < 0) {
                                return
                            }

                            trackIndex -= 1;
                            
                            let nextTrackId: UUID = (vm.order?.trackIds[trackIndex])!
                                                        
                            if let nextTrack = vm.tracks.first(where: { track in track.id == nextTrackId }) {
                                vm.selected = nextTrack;
                                player.stop();
                                playOrToggle();
                            }
                            
                        } label: {
                            Label("", systemImage: "backward.fill")
                            .font(.title2)
                        }.buttonStyle(.borderedProminent)
                        .disabled(vm.selected == nil || trackIndex == 0)
                        
                        Button {
                            playOrToggle()
                        } label: {
                            Label("", systemImage: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.selected == nil)
                        
                        Button {
                            player.stop();
                        } label: {
                            Label("", systemImage: "stop.circle.fill")
                            .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.selected == nil || !player.isPlaying)
                        
                        Button {
                            if (trackIndex + 2 > vm.tracks.count) {
                                return
                            }

                            trackIndex += 1;
                            
                            let nextTrackId: UUID = (vm.order?.trackIds[trackIndex])!
                                                        
                            if let nextTrack = vm.tracks.first(where: { track in track.id == nextTrackId }) {
                                vm.selected = nextTrack;
                                player.stop();
                                playOrToggle();
                            }
                        } label: {
                            Label("", systemImage: "forward.fill")
                            .font(.title2)
                        }.buttonStyle(.borderedProminent)
                        .disabled(vm.selected == nil || trackIndex + 2 > vm.tracks.count)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Моя библиотека")
            .toolbar {
                Button {
                    showingImporter = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
            }
            .onAppear {
                vm.scanAudioFolder()
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff],
            allowsMultipleSelection: true
        ) { result in
            do {
                let urls = try result.get()

                for url in urls {
                    let got = url.startAccessingSecurityScopedResource()
                    
                    defer {
                        if got {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    do {
                        _ = try copyToLibrary(url)
                    } catch {
                        importError = error.localizedDescription
                    }
                }
                vm.scanAudioFolder()  // обновляем список после копирования
            } catch {
                importError = error.localizedDescription
            }
        }
        .alert("Ошибка импорта", isPresented: .constant(importError != nil)) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }
    
    private func copyToLibrary(_ sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let dstBase = AppDirs.audioDir.appendingPathComponent(sourceURL.lastPathComponent)

        // уникализируем имя, если уже есть
        var dst = dstBase

        if fileManager.fileExists(atPath: dst.path) {
            let name = dstBase.deletingPathExtension().lastPathComponent

            let ext  = dstBase.pathExtension

            var i = 2

            repeat {
                let candidate = "\(name) (\(i))" + (ext.isEmpty ? "" : ".\(ext)")

                dst = AppDirs.audioDir.appendingPathComponent(candidate)

                i += 1
            } while fileManager.fileExists(atPath: dst.path)
        }

        try fileManager.copyItem(at: sourceURL, to: dst)

        return dst
    }
    
    private func playOrToggle() {
        guard let track = vm.selected else {
            return
        }

        if playerIsEmptyOrDifferentURL(track.localURL) {
            do {
                try player.load(url: track.localURL)
                player.play()
            } catch {
                print("Playback load error:", error)
            }
        } else {
            // тот же файл — просто Play/Pause
            player.togglePlayPause()
        }
    }
    
    private func playerIsEmptyOrDifferentURL(_ url: URL) -> Bool {
        player.duration == 0
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite && t > 0 else { return "0:00" }

        let s = Int(t)
        return String(format: "%d:%02d", s/60, s%60)
    }
}

#Preview {
    ContentView()
}
