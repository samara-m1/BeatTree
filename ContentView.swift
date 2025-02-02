//
//  ContentView.swift
//  BeatTrees
//
//  Created by Samara Mansoor on 1/31/25.
import SwiftUI

struct Song: Identifiable {
    let id = UUID()
    let trackID: String
    let artists: String
    let albumName: String
    let trackName: String
    let popularity: Int
    let durationMS: Int
    let explicit: Bool
    let danceability: Double
    let energy: Double
    let key: Int
    let loudness: Double
    let mode: Int
    let speechiness: Double
    let acousticness: Double
    let instrumentalness: Double
    let liveness: Double
    let valence: Double
    let tempo: Double
    let timeSignature: Int
    let trackGenre: String
}
class SongViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var Log: [Song] = []
    @Published var showPopup: Bool = false
    @Published var currentSongTitle: String? = nil

    init() {
        loadCSV()
    }

    func loadCSV() {
        DispatchQueue.global(qos: .background).async {
            guard let path = Bundle.main.path(forResource: "dataset", ofType: "csv") else {
                print("CSV file not found")
                return
            }

            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let rows = data.components(separatedBy: "\n")
                var newSongs: [Song] = []

                for row in rows.dropFirst() {
                    let columns = row.components(separatedBy: ",")
                    if columns.count >= 20 {
                        let song = Song(
                            trackID: columns[1],
                            artists: columns[2],
                            albumName: columns[3],
                            trackName: columns[4],
                            popularity: Int(columns[5]) ?? 0,
                            durationMS: Int(columns[6]) ?? 0,
                            explicit: columns[7] == "1",
                            danceability: Double(columns[8]) ?? 0.0,
                            energy: Double(columns[9]) ?? 0.0,
                            key: Int(columns[10]) ?? 0,
                            loudness: Double(columns[11]) ?? 0.0,
                            mode: Int(columns[12]) ?? 0,
                            speechiness: Double(columns[13]) ?? 0.0,
                            acousticness: Double(columns[14]) ?? 0.0,
                            instrumentalness: Double(columns[15]) ?? 0.0,
                            liveness: Double(columns[16]) ?? 0.0,
                            valence: Double(columns[17]) ?? 0.0,
                            tempo: Double(columns[18]) ?? 0.0,
                            timeSignature: Int(columns[19]) ?? 0,
                            trackGenre: columns[20]
                        )
                        newSongs.append(song)
                    }
                }

                // Sort songs by popularity in descending order
                newSongs.sort { $0.popularity > $1.popularity }

                DispatchQueue.main.async {
                    self.songs = newSongs
                }
            } catch {
                print("Error reading CSV file: \(error)")
            }
        }
    }

    func addToLog(_ song: Song) {
        Log.append(song)
        currentSongTitle = song.trackName
        showPopup = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.showPopup = false
                self.currentSongTitle = nil
            }
        }
    }

    func removeFromLog(_ song: Song) {
        if let index = Log.firstIndex(where: { $0.id == song.id }) {
            Log.remove(at: index)
        }
    }
}


struct ContentView: View {
    @State private var searchText = ""
    @ObservedObject var viewModel = SongViewModel()

    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return viewModel.songs
        } else {
            return viewModel.songs.filter { song in
                let searchInTrackName = song.trackName.lowercased().contains(searchText.lowercased())
                let searchInArtist = song.artists.lowercased().contains(searchText.lowercased())
                if let bpmRange = searchText.lowercased().range(of: " bpm") {
                    let tempoText = searchText.prefix(upTo: bpmRange.lowerBound).trimmingCharacters(in: .whitespaces)
                    if let tempo = Double(tempoText) {
                        return song.tempo == tempo
                    }
                }
                return searchInTrackName || searchInArtist
            }
        }
    }

    var body: some View {
        NavigationView {
            
            VStack {
                Text("What are you")
                    .font(.title)
                    .bold()
                    .padding(.top, 10)
                Text("searching for?")
                    .font(.title)
                    .bold()

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search for a song...", text: $searchText)
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                }
                .padding(.horizontal, 16)
                .frame(width: 343, height: 50)
                .background(RoundedRectangle(cornerRadius: 25).fill(Color.white).shadow(radius: 2))
                .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                        ForEach(filteredSongs) { song in
                            NavigationLink(destination: SongDetailView(song: song, viewModel: viewModel)) {
                                VStack(alignment: .leading) {
                                    ZStack {
                                        Circle()
                                            .frame(width: 150, height: 150)
                                            .foregroundColor(.white)
                                        VStack {
                                            Text(song.trackName)
                                                .font(.headline)
                                                .frame(width: 100, height: 50)
                                                .foregroundColor(.black)
                                            Text(String(Int(song.tempo)) + " BPM")
                                                .foregroundColor(.gray)
                                                .font(.body)
                                            Text(song.artists)
                                                .font(.footnote)
                                                .foregroundColor(.gray)
                                                .frame(width: 75, height: 50)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                }
            }
        }
        .overlay(
            VStack {
                if viewModel.showPopup {
                    Text("Added \(viewModel.currentSongTitle ?? "") to Log!")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 50)
        )
    }
}

struct SongDetailView: View {
    var song: Song
    @ObservedObject var viewModel: SongViewModel
    
    var songsWithSameTempo: [Song] {
        viewModel.songs.filter { Int($0.tempo) == Int(song.tempo) && $0.id != song.id }
    }

    var body: some View {
        VStack {
            Text("We found these matches...")
                .font(.title)
                .foregroundColor(.orange)
            ScrollView {
                ZStack {
                    Circle()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.white)
                    VStack {
                        Text(song.trackName)
                            .font(.headline)
                            .frame(width: 150, height: 50)
                            .foregroundColor(.black)
                        Text(String(Int(song.tempo)) + " BPM")
                            .foregroundColor(.gray)
                            .font(.body)
                        Text(song.artists)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 50)
                    }
                }
                .onTapGesture {
                    viewModel.addToLog(song)
                }
                
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(songsWithSameTempo) { similarSong in
                        ZStack {
                            Circle()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white)
                            VStack {
                                Text(similarSong.trackName)
                                    .font(.footnote)
                                    .frame(width: 90, height: 25)
                                    .foregroundColor(.black)
                                Text(String(Int(similarSong.tempo)) + " BPM")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                                Text(similarSong.artists)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .frame(width: 50, height: 25)
                            }
                        }
                        .padding(.vertical, 5)
                        .onTapGesture {
                            viewModel.addToLog(similarSong)
                        }
                    }
                }
            }
            
            .padding()

            // Button to navigate to the Log
            NavigationLink(destination: LogView(viewModel: viewModel)) {
                Text("Go to Song Log")
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                    .padding(.top, 20)
            }
        }
        .padding()
    }
}

struct LogView: View {
    @ObservedObject var viewModel: SongViewModel

    var body: some View {
        VStack {
            Text("Today's Song Log!")
                .font(.title)
                .bold()
                .foregroundColor(.orange)
                .padding(.top, 10)

            List {
                ForEach(viewModel.Log) { song in
                    HStack {
                        Text(song.trackName + " by " + song.artists)
                            .font(.body)
                        Spacer()
                        Button(action: {
                            viewModel.removeFromLog(song)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
