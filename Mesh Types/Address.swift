//
//  Address.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 20/03/2019.
//

import Foundation

/// Bluetooth Mesh address type.
public class Address: Codable {
    
    public let address: UInt16
    
    public init(_ address: UInt16) {
        self.address = address
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let address = UInt16(hex: string) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string")
        }
        self.address = address
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(address.hex)
    }
}

public extension Address {
    
    public static let unassignedAddress: Address = Address(0x0000)
    public static let minUnicastAddress: Address = Address(0x0001)
    public static let maxUnicastAddress: Address = Address(0x7FFF)
    public static let minVirtualAddress: Address = Address(0x8000)
    public static let maxVirtualAddress: Address = Address(0xBFFF)
    public static let minGroupAddress:   Address = Address(0xC000)
    public static let maxGroupAddress:   Address = Address(0xFEFF)
    
    public static let allProxies:        Address = Address(0xFFFC)
    public static let allFriends:        Address = Address(0xFFFD)
    public static let allRelays:         Address = Address(0xFFFE)
    public static let allNodes:          Address = Address(0xFFFF)
    
}

// MARK: - Helper methods

public extension Address {
    
    /// Returns true if the address is from a valid range.
    public func isValidAddress() -> Bool {
        return self < 0xFF00 || self > 0xFFFB
    }
    
    /// Returns true if the address is an Unassigned Address.
    /// Unassigned addresses is equal to 0b0000000000000000.
    public func isUnassigned() -> Bool {
        return self == Address.unassignedAddress
    }
    
    /// Returns true if the address is an Unicat Address.
    /// Unicat addresses match 0b00xxxxxxxxxxxxxx (except 0b0000000000000000).
    public func isUnicast() -> Bool {
        return (self & 0x8000) == 0x0000 && !isUnassigned()
    }
    
    /// Returns true if the address is a Virtual Address.
    /// Virtual addresses match 0b10xxxxxxxxxxxxxx.
    public func isVirtual() -> Bool {
        return (self & 0xC000) == 0x8000
    }
    
    /// Returns true if the address is a Group Address.
    /// Group addresses match 0b11xxxxxxxxxxxxxx.
    public func isGroup() -> Bool {
        return (self & 0xC000) == 0xC000
    }
}

// MARK: - Operators

extension Address: Comparable {
    
    public static func ==(left: UInt16, right: Address) -> Bool {
        return left == right.address
    }
    
    public static func ==(left: Address, right: UInt16) -> Bool {
        return left.address == right
    }
    
    public static func ==(left: Address, right: Address) -> Bool {
        return left.address == right.address
    }
    
    public static func !=(left: UInt16, right: Address) -> Bool {
        return left != right.address
    }
    
    public static func !=(left: Address, right: UInt16) -> Bool {
        return left.address != right
    }
    
    public static func !=(left: Address, right: Address) -> Bool {
        return left.address != right.address
    }
    
    public static func <(left: UInt16, right: Address) -> Bool {
        return left < right.address
    }
    
    public static func <(left: Address, right: UInt16) -> Bool {
        return left.address < right
    }
    
    public static func <(left: Address, right: Address) -> Bool {
        return left.address < right.address
    }
    
    public static func >(left: UInt16, right: Address) -> Bool {
        return left > right.address
    }
    
    public static func >(left: Address, right: UInt16) -> Bool {
        return left.address > right
    }
    
    public static func >(left: Address, right: Address) -> Bool {
        return left.address > right.address
    }
    
    public static func &(left: Address, right: UInt16) -> Address {
        return Address(left.address & right)
    }
    
    public static func |(left: Address, right: UInt16) -> Address {
        return Address(left.address | right)
    }
}
