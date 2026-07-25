//
//  ContainerItem.swift
//  Fuji
//
//  Created by Arsile on 25/07/26.
//

import Foundation
import SwiftUI

struct ContainerItem: Identifiable, Codable, Hashable {
    let id: String
    
    let configuration: Configuration
    let status: Status
    
    var imageReference: String {
        configuration.image.reference
    }
    
    var state: String {
        status.state ?? "unknown"
    }
        
    var ipv4Address: String? {
        status.networks.first?.ipv4Address
    }
    
    struct Configuration: Codable, Hashable {
           let creationDate: Date
           let image: ImageInfo
           let initProcess: InitProcess
           let publishedPorts: [PublishedPort]
           let resources: Resources
           
           enum CodingKeys: String, CodingKey {
               case creationDate = "creationDate"
               case image, initProcess, publishedPorts, resources
           }
       }
       
       struct ImageInfo: Codable, Hashable {
           let reference: String      // e.g., "docker.io/valkey/valkey:latest"
           let descriptor: Descriptor
           
           enum CodingKeys: String, CodingKey {
               case reference, descriptor
           }
       }
       
       struct Descriptor: Codable, Hashable {
           let digest: String
           let mediaType: String
           let size: Int
       }
       
       struct InitProcess: Codable, Hashable {
           let executable: String
           let arguments: [String]
           let environment: [String]
           let workingDirectory: String
       }
       
       struct PublishedPort: Codable, Hashable {
           let containerPort: Int
           let hostPort: Int
           let hostAddress: String
           let proto: String
           
           enum CodingKeys: String, CodingKey {
               case containerPort, hostPort, hostAddress, proto
           }
       }
       
       struct Resources: Codable, Hashable {
           let cpus: Int
           let memoryInBytes: Int64
           
           var memoryFormatted: String {
               let mb = Double(memoryInBytes) / (1024 * 1024)
               return String(format: "%.0f MB", mb)
           }
       }
       
       struct Status: Codable, Hashable {
           let state: String?           // May be missing in some outputs
           let startedDate: Date?
           let networks: [NetworkInfo]
           
           enum CodingKeys: String, CodingKey {
               case state, startedDate, networks
           }
       }
       
       struct NetworkInfo: Codable, Hashable {
           let network: String
           let ipv4Address: String?
           let ipv4Gateway: String?
           let hostname: String
           
           enum CodingKeys: String, CodingKey {
               case network, ipv4Address, ipv4Gateway, hostname
           }
       }
}

enum ContainerStatus: String, Codable, Hashable {
    case running
    case stopped
    case paused
    case created
    case unknown
    
    var color: Color {
        switch self {
        case .running: return .green
        case .stopped, .created: return .gray
        case .paused: return .yellow
        case .unknown: return .red
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        self = ContainerStatus(rawValue: rawValue) ?? .unknown
    }
}
