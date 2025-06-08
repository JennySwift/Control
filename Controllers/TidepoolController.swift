import Foundation

class TidepoolController {
    
    public func fetchTidepoolBGData(email: String, password: String) {
        authenticate(email: email, password: password) { result in
            switch result {
            case .success(let token):
                print("✅ Got session token!")
                
                self.getUserId(token: token) { result in
                    switch result {
                    case .success(let userId):
                        print("✅ Got userId: \(userId)")
                        
                        self.fetchBGData(userId: userId, token: token) { result in
                            switch result {
                            case .success(let bgData):
                                print("✅ Got BG data: \(bgData.count) records")
                            case .failure(let error):
                                print("❌ BG fetch failed: \(error)")
                            }
                        }
                        
                    case .failure(let error):
                        print("❌ Failed to get userId: \(error)")
                    }
                }
                
            case .failure(let error):
                print("❌ Authentication failed: \(error)")
            }
        }
    }

    // MARK: - Step 1: Authenticate
    
    func authenticate(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.tidepool.org/auth/login") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MyApp/1.0", forHTTPHeaderField: "User-Agent")

        let jsonBody: [String: String] = [
            "username": email,       // ✅ Use "username"
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(error ?? NSError(domain: "NoResponse", code: 0)))
                return
            }

            if httpResponse.statusCode == 200,
               let token = httpResponse.allHeaderFields["x-tidepool-session-token"] as? String {
                print("✅ Auth succeeded")
                completion(.success(token))
            } else {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? "<no body>"
                print("❌ Auth failed. Status: \(httpResponse.statusCode)\nBody: \(body)")
                completion(.failure(NSError(domain: "AuthFailed", code: httpResponse.statusCode)))
            }
        }.resume()
    }



    // MARK: - Step 2: Get User ID
    
    func getUserId(token: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.tidepool.org/auth/user")!)
        request.setValue(token, forHTTPHeaderField: "x-tidepool-session-token")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let userId = json["userid"] as? String else {
                completion(.failure(error ?? NSError(domain: "UserIdError", code: 1)))
                return
            }
            completion(.success(userId))
        }.resume()
    }

    // MARK: - Step 3: Fetch BG Data
    
    func fetchBGData(userId: String, token: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let url = URL(string: "https://api.tidepool.org/data/\(userId)?type=smbg")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "x-tidepool-session-token")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                completion(.failure(error ?? NSError(domain: "DataFetchError", code: 2)))
                return
            }

            completion(.success(jsonArray))
        }.resume()
    }
}

