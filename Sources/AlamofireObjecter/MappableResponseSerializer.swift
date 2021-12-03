//
//  MappableResponseSerializer.swift
//  
//
//  Created by Boris Dipner on 12/3/21.
//

import Foundation
import Alamofire
import ObjectMapper

public final class MappableResponseSerializer<T: BaseMappable>: ResponseSerializer {
    /// The `JSONDecoder` instance used to decode responses.
    public let decoder: DataDecoder = JSONDecoder()
    /// HTTP response codes for which empty responses are allowed.
    public let emptyResponseCodes: Set<Int>
    /// HTTP request methods for which empty responses are allowed.
    public let emptyRequestMethods: Set<HTTPMethod>
    
    public let keyPath: String?
    public let context: MapContext?
    public let object: T?

    public let serializeCallback: (URLRequest?,HTTPURLResponse?, Data?,Error?) throws -> T

    /// Creates an instance using the values provided.
    ///
    /// - Parameters:
    ///   - keyPath:
    ///   - object:
    ///   - context:
    ///   - emptyResponseCodes:  The HTTP response codes for which empty responses are allowed. Defaults to
    ///                          `[204, 205]`.
    ///   - emptyRequestMethods: The HTTP request methods for which empty responses are allowed. Defaults to `[.head]`.
    ///   - serializeCallback:
    public init(_ keyPath: String?, mapToObject object: T? = nil, context: MapContext? = nil,
                emptyResponseCodes: Set<Int> = MappableResponseSerializer.defaultEmptyResponseCodes,
                emptyRequestMethods: Set<HTTPMethod> = MappableResponseSerializer.defaultEmptyRequestMethods, serializeCallback: @escaping (URLRequest?,HTTPURLResponse?, Data?,Error?) throws -> T) {

        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
        
        self.keyPath = keyPath
        self.context = context
        self.object = object
        self.serializeCallback = serializeCallback
    }
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        guard error == nil else { throw error! }
        
        guard let data = data, !data.isEmpty else {
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            guard let emptyValue = Empty.value as? T else {
                throw AFError.responseSerializationFailed(reason: .invalidEmptyResponse(type: "\(T.self)"))
            }
            
            return emptyValue
        }
        return try self.serializeCallback(request, response, data, error)
    }
}

public final class MappableArrayResponseSerializer<T: BaseMappable>: ResponseSerializer {
    /// The `JSONDecoder` instance used to decode responses.
    public let decoder: DataDecoder = JSONDecoder()
    /// HTTP response codes for which empty responses are allowed.
    public let emptyResponseCodes: Set<Int>
    /// HTTP request methods for which empty responses are allowed.
    public let emptyRequestMethods: Set<HTTPMethod>
    
    public let keyPath: String?
    public let context: MapContext?

    public let serializeCallback: (URLRequest?,HTTPURLResponse?, Data?,Error?) throws -> [T]
    /// Creates an instance using the values provided.
    ///
    /// - Parameters:
    ///   - keyPath:
    ///   - context:
    ///   - emptyResponseCodes:  The HTTP response codes for which empty responses are allowed. Defaults to
    ///                          `[204, 205]`.
    ///   - emptyRequestMethods: The HTTP request methods for which empty responses are allowed. Defaults to `[.head]`.
    ///   - serializeCallback:
    public init(_ keyPath: String?, context: MapContext? = nil, serializeCallback: @escaping (URLRequest?,HTTPURLResponse?, Data?,Error?) throws -> [T],
                emptyResponseCodes: Set<Int> = MappableArrayResponseSerializer.defaultEmptyResponseCodes,
                emptyRequestMethods: Set<HTTPMethod> = MappableArrayResponseSerializer.defaultEmptyRequestMethods) {
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
        
        self.keyPath = keyPath
        self.context = context
        self.serializeCallback = serializeCallback
    }
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [T] {
        guard error == nil else { throw error! }
        
        guard let data = data, !data.isEmpty else {
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            // TODO / FIX - Empty Response JSON Decodable Array Fix - "Cast from empty always fails..."
            guard let emptyValue = Empty.value as? [T] else {
                throw AFError.responseSerializationFailed(reason: .invalidEmptyResponse(type: "\(T.self)"))
            }
            
            return emptyValue
        }
        return try self.serializeCallback(request, response, data, error)
    }
}
