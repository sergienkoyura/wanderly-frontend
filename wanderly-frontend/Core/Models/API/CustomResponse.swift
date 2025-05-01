//
//  CustomResponse.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

struct CustomResponse<T: Decodable>: Decodable {
    let status: String
    let message: String
    let data: T?
    let metadata: String?
}
