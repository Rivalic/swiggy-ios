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
    
    // Access Control State
    @State private var isVerified = false
    @State private var accessKey = UserDefaults.standard.string(forKey: "AccessKey") ?? ""
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            if isVerified {
                // Main App Content
                ZStack {
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
                }
            } else {
                // Lock Screen
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.orange)
                    
                    Text("Swiggy iOS")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Enter your access key to continue")
                        .foregroundColor(.gray)
                    
                    SecureField("Access Key", text: $accessKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .autocapitalization(.none)
                    
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(action: verifyKey) {
                            Text("Unlock")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
        }
        .statusBarHidden(fullScreen)
        .onAppear {
            if !accessKey.isEmpty {
                verifyKey()
            } else {
                isLoading = false
            }
        }
    }
    
    func verifyKey() {
        guard !accessKey.isEmpty else {
            errorMessage = "Please enter a key"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Remote Key Verification
        guard let url = URL(string: "https://raw.githubusercontent.com/Rivalic/swiggy-ios/main/keys.json") else {
            errorMessage = "Configuration Error"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.errorMessage = "Connection failed: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    let validKeys = try JSONDecoder().decode([String].self, from: data)
                    if validKeys.contains(self.accessKey) {
                        self.isVerified = true
                        UserDefaults.standard.set(self.accessKey, forKey: "AccessKey")
                    } else {
                        self.errorMessage = "Invalid or Revoked Key"
                        self.isVerified = false
                    }
                } catch {
                    self.errorMessage = "Failed to parse key list"
                }
            }
        }.resume()
    }
}

// #Preview {
//     ContentView()
// }
