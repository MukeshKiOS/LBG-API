//
//  RemoteAPILoaderTests.swift
//  APITests
//
//  Created by Apple on 8/6/22.
//
import API
import XCTest

//model structure from remoteAPI successful response
//{
//    "items": [
//        {
//            "id": "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
//            "description": "Description 1",
//            "location": "Location 1",
//            "image": "https://url-1.com",
//        },
//        {
//            "id": "BA298A85-6275-48D3-8315-9C8F7C1CD109",
//            "location": "Location 2",
//            "image": "https://url-2.com",
//        },
//        {
//            "id": "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
//            "description": "Description 3",
//            "image": "https://url-3.com",
//        },
//        {
//            "id": "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
//            "image": "https://url-4.com",
//        },
//        {
//            "id": "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
//            "description": "Description 5",
//            "location": "Location 5",
//            "image": "https://url-5.com",
//        },
//        {
//            "id": "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
//            "description": "Description 6",
//            "location": "Location 6",
//            "image": "https://url-6.com",
//        },
//        {
//            "id": "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
//            "description": "Description 7",
//            "location": "Location 7",
//            "image": "https://url-7.com",
//        },
//        {
//            "id": "F79BD7F8-063F-46E2-8147-A67635C3BB01",
//            "description": "Description 8",
//            "location": "Location 8",
//            "image": "https://url-8.com",
//        }
//    ]
//}

class RemoteAPILoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL()  {
        let (_,client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut,client) = makeSUT(url: url)
        sut.load {_ in}
        XCTAssertEqual(client.requestedURLs, [url])
    }
    func test_loadTwice_requestDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut,client) = makeSUT(url:url)
        sut.load{_ in}
        sut.load{_ in}
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError()  {
       let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
                    let clientError = NSError(domain: "Test", code: 0)
                    client.complete(with: clientError)
                })
    }
    func test_load_deliversErrorOnClientErrorOnNon200HTTPResponse()  {
       let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
            samples.enumerated().forEach { index, code in
                expect(sut, toCompleteWith: .failure(.invalidData), when: {
                    let json = makeItemsJSON([])
                                    client.complete(withStatusCode: code, data: json, at: index)
                            })
        }
    }
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
            let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
                    let invalidJSON = Data(_: "invalid json".utf8)
                    client.complete(withStatusCode: 200, data: invalidJSON)
                })
        }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
            let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
                    let emptyListJSON = makeItemsJSON([])
                    client.complete(withStatusCode: 200, data: emptyListJSON)
                })
        }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
            let (sut, client) = makeSUT()

            let item1 = makeItem(
                id: UUID(),
                imageURL: URL(string: "http://a-url.com")!)

            let item2 = makeItem(
                id: UUID(),
                description: "a description",
                location: "a location",
                imageURL: URL(string: "http://another-url.com")!)

        let items = [item1.model, item2.model]
        expect(sut, toCompleteWith: .success(items), when: {
                    let json = makeItemsJSON([item1.json, item2.json])
                client.complete(withStatusCode: 200, data: json)
            })
        }
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line)->(sut: RemoteAPILoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteAPILoader(url: url, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return(sut, client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
            addTeardownBlock { [weak instance] in
                XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
            }
        }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: APIItems, json: [String: Any]) {
            let item = APIItems(id: id, description: description, location: location, imageURL: imageURL)

            let json = [
                "id": id.uuidString,
                "description": description,
                "location": location,
                "image": imageURL.absoluteString
            ].reduce(into: [String: Any]()) { (acc, e) in
                if let value = e.value { acc[e.key] = value }
            }

            return (item, json)
        }

        private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
            let json = ["items": items]
            return try! JSONSerialization.data(withJSONObject: json)
        }
    private func expect(_ sut: RemoteAPILoader, toCompleteWith result: RemoteAPILoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
            var capturedResults = [RemoteAPILoader.Result]()
            sut.load { capturedResults.append($0) }

            action()

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
        }
    
    
    class HTTPClientSpy: HTTPClient {
        func get(from url: URL, completion: @escaping (HTTPClientResult?) -> Void) {
            messages.append((url, completion))
        }
        
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()

        var requestedURLs: [URL] {
                    return messages.map { $0.url }
                }
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
                    messages.append((url, completion))
                }

                func complete(with error: Error, at index: Int = 0) {
                    messages[index].completion(.failure(error))
                }
        
        func complete(withStatusCode code: Int,  data: Data, at index: Int = 0) {
                    let response = HTTPURLResponse(
                        url: requestedURLs[index],
                        statusCode: code,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    messages[index].completion(.success(data, response))
            
        }
    }
}
