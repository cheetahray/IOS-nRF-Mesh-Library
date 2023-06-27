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

public extension MeshNetworkManager {
    
    /// Encrypts the message with the Application Key and the Network Key
    /// bound to it, and sends to the given destination address.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - destination:    The destination address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    ///   - completion:     The completion handler called when the message
    ///                     has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: MeshMessage,
              from localElement: Element? = nil, to destination: MeshAddress,
              withTtl initialTtl: UInt8? = nil,
              using applicationKey: ApplicationKey,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localNode = meshNetwork.localProvisioner?.node,
              let source = localElement ?? localNode.elements.first else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard source.parentNode == localNode else {
            print("Error: The Element does not belong to the local Node")
            throw AccessError.invalidElement
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        Task {
            do {
                try await send(message, from: localElement, to: destination,
                               withTtl: initialTtl, using: applicationKey)
                if let completion = completion {
                    delegateQueue.async {
                        completion(.success(()))
                    }
                }
            } catch {
                if let completion = completion {
                    delegateQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        return MessageHandle(for: message, sentFrom: destination.address,
                             to: destination, using: networkManager)
    }
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given ``Group``.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - group:          The target Group.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    ///   - completion:     The completion handler called when the message
    ///                     has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: MeshMessage,
              from localElement: Element? = nil, to group: Group,
              withTtl initialTtl: UInt8? = nil,
              using applicationKey: ApplicationKey,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        return try send(message, from: localElement, to: group.address,
                        withTtl: initialTtl, using: applicationKey,
                        completion: completion)
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// ``Model`` and the Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - completion:     The completion handler called when the message
    ///                     has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: UnacknowledgedMeshMessage,
              from localElement: Element? = nil, to model: Model,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let element = model.parentElement else {
            print("Error: Element does not belong to a Node")
            throw AccessError.invalidDestination
        }
        guard let firstKeyIndex = model.bind.first,
              let meshNetwork = meshNetwork,
              let applicationKey = meshNetwork.applicationKeys[firstKeyIndex] else {
            print("Error: Model is not bound to any Application Key")
            throw AccessError.modelNotBoundToAppKey
        }
        return try send(message, from: localElement, to: MeshAddress(element.unicastAddress),
                        withTtl: initialTtl, using: applicationKey,
                        completion: completion)
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// ``Model``s and the Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    ///   - completion:   The completion handler called when the message
    ///                   has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: UnacknowledgedMeshMessage,
              from localModel: Model, to model: Model,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let localElement = localModel.parentElement else {
            print("Error: Source Model does not belong to an Element")
            throw AccessError.invalidSource
        }
        return try send(message, from: localElement, to: model,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// Model and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    ///   - completion:     The completion handler called when the response
    ///                     has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: AcknowledgedMeshMessage,
              from localElement: Element? = nil, to model: Model,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<MeshResponse, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let element = model.parentElement else {
            print("Error: Element does not belong to a Node")
            throw AccessError.invalidDestination
        }
        guard let firstKeyIndex = model.bind.first,
              let _ = meshNetwork.applicationKeys[firstKeyIndex] else {
            print("Error: Model is not bound to any Application Key")
            throw AccessError.modelNotBoundToAppKey
        }
        guard let localNode = meshNetwork.localProvisioner?.node,
              let source = localElement ?? localNode.elements.first else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard source.parentNode == localNode else {
            print("Error: The Element does not belong to the local Node")
            throw AccessError.invalidElement
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        Task {
            do {
                let response = try await send(message, from: source, to: model,
                               withTtl: initialTtl)
                if let completion = completion {
                    delegateQueue.async {
                        completion(.success(response))
                    }
                }
            } catch {
                if let completion = completion {
                    delegateQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        return MessageHandle(for: message, sentFrom: source.unicastAddress,
                             to: MeshAddress(element.unicastAddress), using: networkManager)
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// Models and a Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    ///   - completion:   The completion handler which is called when the response
    ///                   has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: AcknowledgedMeshMessage,
              from localModel: Model, to model: Model,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<MeshResponse, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let localElement = localModel.parentElement else {
            print("Error: Source Model does not belong to an Element")
            throw AccessError.invalidSource
        }
        return try send(message, from: localElement, to: model,
                        withTtl: initialTtl)
    }
    
    /// Sends a Configuration Message to the Node with given destination address
    /// and returns the received response.
    ///
    /// The `destination` must be a Unicast Address, otherwise the method
    /// throws an ``AccessError/invalidDestination`` error.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:     The message to be sent.
    ///   - destination: The destination Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    ///   - completion:  The completion handler called when the message
    ///                  has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: UnacknowledgedConfigMessage, to destination: Address,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localProvisioner = meshNetwork.localProvisioner,
              let element = localProvisioner.node?.primaryElement else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard destination.isUnicast else {
            print("Error: Address: 0x\(destination.hex) is not a Unicast Address")
            throw AccessError.invalidDestination
        }
        guard let node = meshNetwork.node(withAddress: destination) else {
            print("Error: Unknown destination Node")
            throw AccessError.invalidDestination
        }
        guard let _ = node.networkKeys.first else {
            print("Fatal Error: The target Node does not have Network Key")
            throw AccessError.invalidDestination
        }
        guard let _ = node.deviceKey else {
            print("Error: Node's Device Key is unknown")
            throw AccessError.noDeviceKey
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        Task {
            do {
                try await send(message, to: destination, withTtl: initialTtl)
                if let completion = completion {
                    delegateQueue.async {
                        completion(.success(()))
                    }
                }
            } catch {
                if let completion = completion {
                    delegateQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        return MessageHandle(for: message, sentFrom: element.unicastAddress,
                             to: MeshAddress(destination), using: networkManager)
    }
    
    /// Sends a Configuration Message to the primary Element on the given ``Node``.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:    The message to be sent.
    ///   - node:       The destination Node.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - completion:  The completion handler called when the message
    ///                  has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: UnacknowledgedConfigMessage, to node: Node,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        return try send(message, to: node.primaryUnicastAddress,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Sends Configuration Message to the Node with given destination Address.
    ///
    /// The `destination` must be a Unicast Address, otherwise the method
    /// throws an ``AccessError/invalidDestination`` error.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:     The message to be sent.
    ///   - destination: The destination Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    ///   - completion:  The completion handler which is called when the response
    ///                  has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: AcknowledgedConfigMessage, to destination: Address,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<ConfigResponse, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localProvisioner = meshNetwork.localProvisioner,
              let source = localProvisioner.node?.primaryElement else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard destination.isUnicast else {
            print("Error: Address: 0x\(destination.hex) is not a Unicast Address")
            throw AccessError.invalidDestination
        }
        guard let node = meshNetwork.node(withAddress: destination) else {
            print("Error: Unknown destination Node")
            throw AccessError.invalidDestination
        }
        guard let _ = node.networkKeys.first else {
            print("Fatal Error: The target Node does not have Network Key")
            throw AccessError.invalidDestination
        }
        guard let _ = node.deviceKey else {
            print("Error: Node's Device Key is unknown")
            throw AccessError.noDeviceKey
        }
        if message is ConfigNetKeyDelete {
            guard node.networkKeys.count > 1 else {
                print("Error: Cannot remove last Network Key")
                throw AccessError.cannotDelete
            }
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        Task {
            do {
                let response = try await send(message, to: destination, withTtl: initialTtl)
                if let completion = completion {
                    delegateQueue.async {
                        completion(.success(response))
                    }
                }
            } catch {
                if let completion = completion {
                    delegateQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        return MessageHandle(for: message, sentFrom: source.unicastAddress,
                             to: MeshAddress(destination), using: networkManager)
    }
    
    /// Sends a Configuration Message to the primary Element on the given ``Node``.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:    The message to be sent.
    ///   - node:       The destination Node.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - completion: The completion handler which is called when the response
    ///                 has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: AcknowledgedConfigMessage, to node: Node,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<ConfigResponse, Error>) -> ())? = nil) throws -> MessageHandle {
        return try send(message, to: node.primaryUnicastAddress,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Sends the Configuration Message to the primary Element of the local Node.
    ///
    /// Apart from the `completion` callback, an appropriate callback of the
    /// ``MeshNetworkDelegate`` will be called when the message has been sent
    /// successfully or a problem occured. 
    ///
    /// - parameter message: The acknowledged configuration message to be sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           or the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned).
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func sendToLocalNode(_ message: AcknowledgedConfigMessage,
                         completion: ((Result<ConfigResponse, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localProvisioner = meshNetwork.localProvisioner,
              let destination = localProvisioner.primaryUnicastAddress else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        return try send(message, to: destination, withTtl: 1)
    }
    
}