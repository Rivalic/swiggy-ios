//
//  ContentView.swift
//  PakePlus
//
//  Created by Song on 2025/3/29.
//

import SwiftUI
import WebKit

struct ContentView: View {
    // read value from info
    let webUrl = Bundle.main.object(forInfoDictionaryKey: "WEBURL") as? String ?? ""
    let debug = Bundle.main.object(forInfoDictionaryKey: "DEBUG") as? Bool ?? false
    let fullScreen = Bundle.main.object(forInfoDictionaryKey: "FULLSCREEN") as? Bool ?? false
    @State private var showAlert = false

    var body: some View {
        // BottomMenuView()
        ZStack {
            // background color
            // Color.white
            //     .ignoresSafeArea()
            // webview
            WebView(webUrl: URL(string: webUrl)!, debug: debug)
                .ignoresSafeArea(edges: [.all])
            
            VStack {
                Spacer()
                HStack {
                    Spacer()


                    // Claim Offers Button
                    Button(action: {
                        print("Posting TriggerCoupons notification...")
                        NotificationCenter.default.post(name: NSNotification.Name("TriggerCoupons"), object: nil)
                    }) {
                        Image(systemName: "gift.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.bottom)
                    
                    // Reset Device ID Button
                    Button(action: {
                        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0)) {
                            print("Manually cleared device ID data")
                            DispatchQueue.main.async {
                                self.showAlert = true
                            }
                        }
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.orange)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Device ID Reset"), message: Text("All session data has been cleared. You can now log in as a new user."), dismissButton: .default(Text("OK")))
                    }
                }
            }
        }.statusBarHidden(fullScreen)
    }
}

// #Preview {
//     ContentView()
// }
