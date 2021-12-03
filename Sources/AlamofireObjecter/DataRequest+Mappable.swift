//
//  DataRequest+Mappable.swift
//  
//
//  Created by Boris Dipner on 12/3/21.
//

import Foundation
import Alamofire
import ObjectMapper

public extension DataRequest {
    
    enum ErrorCode: Int {
        case noData = 1
        case dataSerializationFailed = 2
    }
    
    /// Utility function for extracting JSON from response
    static func processResponse(request: URLRequest?, response: HTTPURLResponse?, data: Data?, keyPath: String?) -> Any? {
        
        let jsonResponseSerializer = JSONResponseSerializer(options: .allowFragments)
        if let result = try? jsonResponseSerializer.serialize(request: request, response: response, data: data, error: nil) {
            
            let JSON: Any?
            if let keyPath = keyPath , keyPath.isEmpty == false {
                JSON = (result as AnyObject?)?.value(forKeyPath: keyPath)
            } else {
                JSON = result
            }
            
            return JSON
        }
        
        return nil
    }
    
    internal static func newError(_ code: ErrorCode, failureReason: String) -> NSError {
        let errorDomain = "com.alamofireobjectmapper.error"
        
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
        
        return returnError
    }
    
    /// Utility function for checking for errors in response
    internal static func checkResponseForError(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) -> Error? {
        if let error = error {
            return error
        }
        guard let _ = data else {
            let failureReason = "Data could not be serialized. Input data was nil."
            let error = newError(.noData, failureReason: failureReason)
            return error
        }
        return nil
    }
    
    
    /// BaseMappable Object Serializer
    static func ObjectMapperSerializer<T: BaseMappable>(_ keyPath: String?, mapToObject object: T? = nil, context: MapContext? = nil) -> MappableResponseSerializer<T> {
        
        return MappableResponseSerializer(keyPath, mapToObject: object, context: context, serializeCallback: {
            request, response, data, error in
            
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            
            if let object = object {
                _ = Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: JSONObject, toObject: object)
                return object
            } else if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: JSONObject){
                return parsedObject
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            throw AFError.responseSerializationFailed(reason: .decodingFailed(error: newError(.dataSerializationFailed, failureReason: failureReason)))
            
        })
    }
    
    /// ImmutableMappable Array Serializer
    static func ObjectMapperImmutableSerializer<T: ImmutableMappable>(_ keyPath: String?, context: MapContext? = nil) -> MappableResponseSerializer<T> {
        
        return MappableResponseSerializer(keyPath, context: context, serializeCallback: {
            request, response, data, error in
            
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            
            if let JSONObject = JSONObject,
               let parsedObject = (try? Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: JSONObject) as T) {
                return parsedObject
            } else {
                let failureReason = "ObjectMapper failed to serialize response."
                throw AFError.responseSerializationFailed(reason: .decodingFailed(error: newError(.dataSerializationFailed, failureReason: failureReason)))
            }
        })
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue:             The queue on which the completion handler is dispatched.
     - parameter keyPath:           The key path where object mapping should be performed
     - parameter object:            An object to perform the mapping on to
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - returns: The request.
     */
    @discardableResult
    func responseObject<T: BaseMappable>(queue: DispatchQueue = .main,
                                                keyPath: String? = nil,
                                                mapToObject object: T? = nil,
                                                context: MapContext? = nil,
                                                completionHandler: @escaping (AFDataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperSerializer(keyPath, mapToObject: object, context: context), completionHandler: completionHandler)
    }
    
    @discardableResult
    func responseObject<T: ImmutableMappable>(queue: DispatchQueue = .main, keyPath: String? = nil, mapToObject object: T? = nil, context: MapContext? = nil, completionHandler: @escaping (AFDataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperImmutableSerializer(keyPath, context: context), completionHandler: completionHandler)
    }
    
    /// BaseMappable Array Serializer
    static func ObjectMapperArraySerializer<T: BaseMappable>(_ keyPath: String?, context: MapContext? = nil) -> MappableArrayResponseSerializer<T> {
        
        
        
        return MappableArrayResponseSerializer(keyPath, context: context, serializeCallback: {
            request, response, data, error in
            
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            
            if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).mapArray(JSONObject: JSONObject){
                return parsedObject
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            throw AFError.responseSerializationFailed(reason: .decodingFailed(error: newError(.dataSerializationFailed, failureReason: failureReason)))
        })
    }
    
    
    /// ImmutableMappable Array Serializer
    static func ObjectMapperImmutableArraySerializer<T: ImmutableMappable>(_ keyPath: String?, context: MapContext? = nil) -> MappableArrayResponseSerializer<T> {
        return MappableArrayResponseSerializer(keyPath, context: context, serializeCallback: {
            request, response, data, error in
            
            if let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath){
                
                if let parsedObject = try? Mapper<T>(context: context, shouldIncludeNilValues: false).mapArray(JSONObject: JSONObject) as [T] {
                    return parsedObject
                }
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            throw AFError.responseSerializationFailed(reason: .decodingFailed(error: newError(.dataSerializationFailed, failureReason: failureReason)))
        })
    }
    
    @discardableResult
    func responseArray<T: BaseMappable>(queue: DispatchQueue = .main,
                                        keyPath: String? = nil,
                                        context: MapContext? = nil,
                                        completionHandler: @escaping (AFDataResponse<[T]>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperArraySerializer(keyPath, context: context), completionHandler: completionHandler)
    }
    
    @discardableResult
    func responseArray<T: ImmutableMappable>(queue: DispatchQueue = .main,
                                             keyPath: String? = nil,
                                             context: MapContext? = nil,
                                             completionHandler: @escaping (AFDataResponse<[T]>) -> Void) -> Self {
        return response(queue: queue,
                        responseSerializer: DataRequest.ObjectMapperImmutableArraySerializer(keyPath, context: context),
                        completionHandler: completionHandler)
    }
}
