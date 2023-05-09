//
//  BaseModel.swift
//  BASwiftToolkit
//
//  Created by An Nguyen on 08/05/2023.
//

import Foundation

public protocol BaseModel: Codable {

}

public protocol EquatableObject: Hashable, BaseModel {
    
}

extension BaseModel where Self: EquatableObject {
    static func ==(lhs: Self , rhs: Self) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
