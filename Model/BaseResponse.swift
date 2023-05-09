//
//  BaseResponse.swift
//  BASwiftToolkit
//
//  Created by An Nguyen on 08/05/2023.
//

import Foundation

public struct BaseResponse<T:BaseModel>: BaseModel {
    public var data: T?
    
    public enum CodingKeys: String, CodingKey {
        case data
    }
}

public struct BaseResponseArray<T:BaseModel>: BaseModel {
    public var data: [T]?
    
    public enum CodingKeys: String, CodingKey {
        case data
    }
}

public struct ArrayWrapperItem<T:BaseModel>: BaseModel {
    public var items: ArrayItem<T>
    public enum CodingKeys: String, CodingKey {
        case items
    }
}

public struct ArrayItem<T: BaseModel>: BaseModel {
    public var items: [T]
    
    public enum CodingKeys: String, CodingKey {
        case items
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        items = try container.decode(Array.self)
    }
}

public struct ArrayString: BaseModel {
    public var items: [String]
    public enum CodingKeys: String, CodingKey {
        case items
    }
}

public struct ArrayInt: BaseModel {
    public var items: [Int]
    public enum CodingKeys: String, CodingKey {
        case items
    }
}

public struct BaseError: BaseModel, Error {
    public var statusCode: Int = 0
    public var message: ErrorMessage = ErrorMessage()
    public var error: String = ""
}

public struct ErrorMessage: BaseModel {
    public var target: String = ""
    public var message: String = ""
}

public struct SuccessMessage: BaseModel {
    public var statusCode: Int = 200
    public var message: String = ""
}

public struct CountInt: BaseModel {
    public var count: Int
    public enum CodingKeys: String, CodingKey {
        case count
    }
}
