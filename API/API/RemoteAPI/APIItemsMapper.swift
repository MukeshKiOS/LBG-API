//
//  APIItemsMapper.swift
//  API
//
//  Created by Apple on 8/8/22.
//

import Foundation

//public class APIItemsMapper {
//    private struct Root: Decodable {
//        let items: [Item]
//        var feed: [APIItems]{
//            return items.map { $0.item }
//        }
//    }
//
//    private struct Item: Decodable {
//        let id: UUID
//        let description: String?
//        let location: String?
//        let image: URL
//
//        var item: APIItems {
//            return APIItems(id: id, description: description, location: location, imageURL: image)
//        }
//    }
//
//    private static var OK_200: Int { return 200 }
//
//    public static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteAPILoader.Result {
//            guard response.statusCode == OK_200,
//                let root = try? JSONDecoder().decode(Root.self, from: data) else {
//                return .failure(.invalidData)
//        }
//        return  .success(root.feed)
//    }
//}
