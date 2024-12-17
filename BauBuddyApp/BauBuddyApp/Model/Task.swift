//
//  Task.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import Foundation

struct Task: Codable, Hashable {
    let title: String
    let description: String?
    let colorCode: String?
}

