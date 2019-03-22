//
//  Scene.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class Scene: Codable {
    
    public let scene: UInt16
    
    public init(_ scene: UInt16) {
        self.scene = scene
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let scene = UInt16(hex: string) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Scene must be 4-character hexadecimal string")
        }
        self.scene = scene
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(scene.hex)
    }
}

extension Scene {
    
    public static let invalid:  Scene = Scene(0x0000)
    public static let minScene: Scene = Scene(0x0001)
    public static let maxScene: Scene = Scene(0xFFFF)
    
}

// MARK: - Helper methods

extension Scene {
    
    public func isValidScene() -> Bool {
        return self.scene != Scene.invalid
    }
    
}

// MARK: - Operators

extension Scene: Comparable {
    
    public static func ==(left: UInt16, right: Scene) -> Bool {
        return left == right.scene
    }
    
    public static func ==(left: Scene, right: UInt16) -> Bool {
        return left.scene == right
    }
    
    public static func ==(left: Scene, right: Scene) -> Bool {
        return left.scene == right.scene
    }
    
    public static func !=(left: UInt16, right: Scene) -> Bool {
        return left != right.scene
    }
    
    public static func !=(left: Scene, right: UInt16) -> Bool {
        return left.scene != right
    }
    
    public static func !=(left: Scene, right: Scene) -> Bool {
        return left.scene != right.scene
    }
    
    public static func <(left: UInt16, right: Scene) -> Bool {
        return left < right.scene
    }
    
    public static func <(left: Scene, right: UInt16) -> Bool {
        return left.scene < right
    }
    
    public static func <(left: Scene, right: Scene) -> Bool {
        return left.scene < right.scene
    }
    
    public static func >(left: UInt16, right: Scene) -> Bool {
        return left > right.scene
    }
    
    public static func >(left: Scene, right: UInt16) -> Bool {
        return left.scene > right
    }
    
    public static func >(left: Scene, right: Scene) -> Bool {
        return left.scene > right.scene
    }
    
    public static func &(left: Scene, right: UInt16) -> Scene {
        return Scene(left.scene & right)
    }
    
    public static func |(left: Scene, right: UInt16) -> Scene {
        return Scene(left.scene | right)
    }
}
