//
//  RemoteAPILoader.swift
//  API
//
//  Created by Apple on 8/6/22.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}
public protocol HTTPClient{
    func get(from url: URL, completion: @escaping ( HTTPClientResult?)-> Void)
}

public final class RemoteAPILoader{
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
        case none
    }
    
    public enum Result: Equatable {
            case success([APIItems])
            case failure(Error)
        }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    public func load(completion: @escaping (Result) -> Void) {
            client.get(from: url) { result in
                switch result {
                case let .success(data, response):
                    do {
                                        let items = try APIItemsMapper.map(data, response)
                                        completion(.success(items))
                                    } catch {
                                    completion(.failure(.invalidData))
                                }
                    //completion(APIItemsMapper.map(data, from: response))
                case .failure:
                    completion(.failure(.invalidData))
               
                case .none:
                    completion(.failure(.connectivity))
                
                }
            }
    }
    
    private class APIItemsMapper {
        private struct Root: Decodable {
            let items: [Item]
        }
        private struct Item: Decodable {
                let id: UUID
                let description: String?
                let location: String?
                let image: URL

                var item: APIItems {
                    return APIItems(id: id, description: description, location: location, imageURL: image)
                }
            }

            static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [APIItems] {
                guard response.statusCode == 200 else {
                    throw RemoteAPILoader.Error.invalidData
                }

                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.items.map { $0.item }
            }
    }
}
