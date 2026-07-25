//
//  ContainerManager.swift
//  Fuji
//
//  Created by Arsile on 25/07/26.
//

import Observation
import SwiftUI

@Observable
@MainActor
class ContainerManager {
    var containers: [ContainerItem] = []
    var isLoading = false
    var errorMessage: String?
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let jsonString = try await CLI.run(arguments: ["ls", "--format", "json"])
            
            if let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                self.containers = try decoder.decode([ContainerItem].self, from: jsonData)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("CLI Error: \(error)")
        }
    }
    
    func stopContainer(id: String) async {
        do {
            try await CLI.run(arguments: ["stop", id])
            await refresh()
        } catch {
            self.errorMessage = "Failed to stop: \(error.localizedDescription)"
        }
    }
}
