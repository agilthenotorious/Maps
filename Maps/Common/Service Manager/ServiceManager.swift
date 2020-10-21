//
//  ServiceManager.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import Foundation

class ServiceManager {
        
    static let manager = ServiceManager()
    
    private init() {}
    
    // swiftlint:disable:next variable_name
    func request<T: Decodable>(_ t: T.Type, withRequest urlRequest: URLRequest, completion: @escaping (Result<T, CustomError>) -> Void) {
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse, (response.statusCode == 200) else {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError))
                    }
                return
            }
            do {
                let obj = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(obj))
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailed))
                }
            }
        }
        task.resume()
    }
}
