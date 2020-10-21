//
//  CustomError.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import Foundation

enum CustomError: Error {
    case serverError
    case decodingFailed
    case emptyTextField
    case noLocationFound
}
