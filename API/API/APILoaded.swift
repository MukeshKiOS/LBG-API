//
//  APILoaded.swift
//  API
//
//  Created by Apple on 8/6/22.
//

import Foundation

enum LoadFeedResult {
    case success([APIItems])
    case error(Error)
}
protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
