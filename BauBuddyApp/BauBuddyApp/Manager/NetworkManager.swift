//
//  NetworkManager.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import Foundation
import CoreData
import SystemConfiguration
class NetworkManager{
    // Singleton instance
    static let shared = NetworkManager()
    private init() {}
    
    // Base URL
    private let baseURL = "https://api.baubuddy.de/index.php"
    
    // Authentication credentials
    private let basicAuthHeader = "Basic QVBJX0V4cGxvcmVyOjEyMzQ1NmlzQUxhbWVQYXNz"
    
    // Store access token
    private var accessToken: String?
    
    // Authentication struct
    struct LoginCredentials: Codable {
        let username: String
        let password: String
    }

    // Check internet connectivity
    func isConnectedToInternet() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
    }
    // Perform login and get access token
    func login(completion: @escaping (Result<String, Error>) -> Void) {
        // Prepare login request
        guard let url = URL(string: "\(baseURL)/login") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        
        // Prepare credentials
        let credentials = LoginCredentials(username: "365", password: "1")
        
        do {
            request.httpBody = try JSONEncoder().encode(credentials)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Perform network request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Check for errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Verify HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            // Parse JSON
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                // Extract access token
                if let oauth = jsonResponse?["oauth"] as? [String: Any],
                   let accessToken = oauth["access_token"] as? String {
                    self?.accessToken = accessToken
                    completion(.success(accessToken))
                } else {
                    completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not extract access token"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    // Updated fetch tasks method to work with CoreData
    func fetchTasksFromAPI(completion: @escaping (Result<[Task], Error>) -> Void) {
        // Ensure we have an access token
        guard let accessToken = accessToken,
              let url = URL(string: "https://api.baubuddy.de/dev/index.php/v1/tasks/select") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL or missing token"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Error handling
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Verify HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            // Parse JSON
            do {
                let tasks = try JSONDecoder().decode([Task].self, from: data)
                completion(.success(tasks))
                print(tasks)
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
