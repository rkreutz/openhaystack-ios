//
//  AccessoryLocalDTO.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation

struct AccessoryLocalDTO: Codable {
    struct Color: Codable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double
    }
    
    var id: String
    var name: String
    var imageName: String
    var color: Color
}
