//
//  ContentView.swift
//  Demo
//
//  Created by Vishal davara on 25/04/24.
//

import SwiftUI
import Foundation
import AVFoundation
import AVKit

final class AppState: ObservableObject {
    @Published var hlsURLString: String = ""
    @Published var isDRMProtected: Bool = false
    @Published var certificateURLString: String = ""
    @Published var licenseServerURLString: String = ""
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var downloadManager = OfflineDownloadManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Source")) {
                    TextField("HLS URL (m3u8)", text: $appState.hlsURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Toggle("FairPlay DRM", isOn: $appState.isDRMProtected)
                    if appState.isDRMProtected {
                        TextField("Certificate URL", text: $appState.certificateURLString)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        TextField("License Server URL", text: $appState.licenseServerURLString)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    Button("Download") { startDownload() }
                        .disabled(URL(string: appState.hlsURLString) == nil)
                }

                Section(header: Text("Downloads")) {
                    ForEach(Array(downloadManager.downloads.values).sorted(by: { $0.title < $1.title })) { info in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(info.title)
                                ProgressView(value: info.progress)
                            }
                            Spacer()
                            if let local = info.localURL {
                                NavigationLink("Play") { OfflinePlayerView(localURL: local) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Offline VOD")
        }
    }
    
    private func startDownload() {
        guard let url = URL(string: appState.hlsURLString) else { return }
        if appState.isDRMProtected,
           let certURL = URL(string: appState.certificateURLString),
           let licenseURL = URL(string: appState.licenseServerURLString) {
            downloadManager.configureFairPlay(certificateURL: certURL, licenseURL: licenseURL)
        }
        downloadManager.startDownload(hlsURL: url, title: url.lastPathComponent)
    }
}

#Preview {
    ContentView()
}
