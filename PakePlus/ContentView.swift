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
                        HStack {
                            // Claim Offers Button (Top-Left)
                            Button(action: {
                                print("Posting TriggerCoupons notification...")
                                NotificationCenter.default.post(name: NSNotification.Name("TriggerCoupons"), object: nil)
                            }) {
                                Image(systemName: "gift.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                                    .opacity(0.8)
                            }
                            .padding(.leading)
                            .padding(.top)
                            
                            // Reset Device ID Button (Top-Left)
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
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.orange)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                                    .opacity(0.8)
                            }
                            .padding(.top)
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("Device ID Reset"), message: Text("All session data has been cleared. You can now log in as a new user."), dismissButton: .default(Text("OK")))
                            }
                            
                            Spacer()
                        }
                        Spacer()
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
        
        // Google Script Web App URL
        guard let url = URL(string: "https://script.google.com/macros/s/AKfycbzQsqtvVr5y1C0BySK0bDYmVk-Hz_0aHrPv1KDOveYi0MhC3J-KCZzG8IkQF_mT07dJYw/exec") else {
            errorMessage = "Configuration Error"
            isLoading = false
            return
        }
        
        // Prepare Payload
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownDevice"
        let parameters: [String: Any] = [
            "key": accessKey,
            "deviceId": deviceId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/plain", forHTTPHeaderField: "Content-Type") // Apps Script prefers text/plain or application/json to handle doPost correctly with CORS sometimes, but let's try standard JSON first or handle as string in script. The script I gave parses JSON.
        // Actually, with standard fetch in JS/Apps Script, simple POST body is easiest.
        // let's stick to JSON body.
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            errorMessage = "Failed to encode data"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
                
                // Debug response
                if let str = String(data: data, encoding: .utf8) {
                    print("Server Response: \(str)")
                }
                
                do {
                    // Script returns {"status":"success"} or {"status":"error", "message":"..."}
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let status = json["status"] as? String, status == "success" {
                            self.isVerified = true
                            UserDefaults.standard.set(self.accessKey, forKey: "AccessKey")
                        } else {
                            self.isVerified = false
                            let msg = json["message"] as? String ?? "Validation Failed"
                            self.errorMessage = msg
                        }
                    } else {
                        self.errorMessage = "Invalid server response"
                    }
                } catch {
                    self.errorMessage = "Failed to parse server response"
                }
            }
        }.resume()
    }
}

// #Preview {
//     ContentView()
// }
