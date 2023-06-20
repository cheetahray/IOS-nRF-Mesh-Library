/*
* Copyright (c) 2023, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// A Private Node Identity Set message is an acknowledged message used to set the
/// current Private Node Identity state for a subnet.
public struct PrivateNodeIdentitySet: AcknowledgedConfigMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8067
    public typealias ResponseType = PrivateNodeIdentityStatus
    
    public let networkKeyIndex: KeyIndex
    /// Should advertising with Private Node Identity for a subnet be enabled.
    public let enabled: Bool
    
    public var parameters: Data? {
        return encodeNetKeyIndex() + enabled
    }
    
    public init(enabled: Bool, for networkKey: NetworkKey) {
        self.networkKeyIndex = networkKey.index
        self.enabled = enabled
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        networkKeyIndex = PrivateNodeIdentityGet.decodeNetKeyIndex(from: parameters, at: 0)
        enabled = parameters[2] == 0x01
    }
}
