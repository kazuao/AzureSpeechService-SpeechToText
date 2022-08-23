//
//  RequestBuilder.swift
//  CustomURLRequest
//
//  Created by kazunori.aoki on 2022/07/28.
//

import Foundation
import SwiftUI

// ref: https://github.com/ParableHealth/URLRequestBuilder
struct RequestBuilder {
    var buildURLRequest: (inout URLRequest) -> Void
    var urlComponents: URLComponents

    private init(urlComponents: URLComponents) {
        self.urlComponents = urlComponents
        self.buildURLRequest = { _ in }
    }

    init(path: String) {
        var components = URLComponents()
        components.path = path
        self.init(urlComponents: components)
    }

    static func customURL(_ url: URL) -> RequestBuilder {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("can't make URLComponents from URL")
            return RequestBuilder(urlComponents: .init())
        }

        return RequestBuilder(urlComponents: components)
    }
}

// MARK: - Public
// MARK: - Factories
extension RequestBuilder {

    // MARK: GET
    static func get(path: String) -> RequestBuilder {
        RequestBuilder(path: path)
            .method(.get)
    }

    // MARK: POST
    static func post(path: String) -> RequestBuilder {
        RequestBuilder(path: path)
            .method(.post)
    }

    // MARK: JSON GET
    static func jsonGet(path: String) -> RequestBuilder {
        self.get(path: path)
            .httpHeader(name: "Content-Type", value: "application/json")
    }

    // MARK: JSON POST
    static func jsonPost(path: String, jsonData: Data) -> RequestBuilder {
        self.post(path: path)
            .httpHeader(name: "Content-Type", value: "application/json")
            .body(jsonData)
    }

    // MARK: JSON POST Encodable
    static func jsonPost<Content: Encodable>(path: String, jsonObject: Content, encoder: JSONEncoder = RequestBuilder.jsonEncoder) throws -> RequestBuilder {
        try self.post(path: path)
            .httpHeader(name: "Content-Type", value: "application/json")
            .jsonBody(jsonObject, encoder: encoder)
    }
}

// MARK: Make Request
extension RequestBuilder {
    func makeRequest(withBaseURL baseURL: URL) -> URLRequest {
        makeRequest(withConfig: .baseURL(baseURL))
    }

    func makeRequest(withConfig config: RequestConfiguration) -> URLRequest {
        config.configureRequest(self)
    }
}

// MARK: HTTP Query
extension RequestBuilder {
    func queryItems(_ queryItems: [URLQueryItem]) -> RequestBuilder {
        modifyComponents { urlComponents in
            var items = urlComponents.queryItems ?? []
            items.append(contentsOf: queryItems)
            urlComponents.queryItems = items
        }
    }

    func queryItems(_ queryItems: KeyValuePairs<String, String>) -> RequestBuilder {
        self.queryItems(queryItems.map { .init(name: $0.key, value: $0.value) })
    }

    func queryItem(name: String, value: String) -> RequestBuilder {
        queryItems([name: value])
    }
}

// MARK: HTTP Body
extension RequestBuilder {
    static let jsonEncoder = JSONEncoder()

    func body(_ body: Data, setContentLength: Bool = false) -> RequestBuilder {
        let updated = modifyRequest { $0.httpBody = body }
        if setContentLength {
            return updated.contentLength(body.count)
        } else {
            return updated
        }
    }

    func jsonBody<Content: Encodable>(_ body: Content, encoder: JSONEncoder = RequestBuilder.jsonEncoder, setContentLength: Bool = false) throws -> RequestBuilder {
        let body = try encoder.encode(body)
        return self.body(body)
    }
}

// MARK: Timeout
extension RequestBuilder {
    func timeout(_ timeout: TimeInterval) -> RequestBuilder {
        modifyRequest { $0.timeoutInterval = timeout }
    }
}

// MARK: HTTP Method
extension RequestBuilder {
    func method(_ method: HTTPMethod) -> RequestBuilder {
        modifyRequest { $0.httpMethod = method.rawValue }
    }
}

// MARK: Config
extension RequestBuilder {
    struct RequestConfiguration {
        let configureRequest: (RequestBuilder) -> URLRequest

        init(configureRequest: @escaping (RequestBuilder) -> URLRequest) {
            self.configureRequest = configureRequest
        }
    }
}

// MARK: Helper
extension RequestBuilder {
    func contentLength(_ length: Int) -> RequestBuilder {
        header(name: .contentLength, value: String(length))
    }

    func header(name: HeaderName, value: String) -> RequestBuilder {
        modifyRequest { $0.addValue(value, forHTTPHeaderField: name.rawValue) }
    }

    func header(name: HeaderName, values: [String]) -> RequestBuilder {
        var copy = self
        for value in values {
            copy = copy.header(name: name, value: value)
        }
        return copy
    }
}


// MARK: - Private
// MARK: Build Request / Components
private extension RequestBuilder {
    func modifyComponents(_ modifyURLComponents: @escaping (inout URLComponents) -> Void) -> RequestBuilder {
        var copy = self
        modifyURLComponents(&copy.urlComponents)
        return copy
    }

    func modifyRequest(_ modifyURLRequest: @escaping (inout URLRequest) -> Void) -> RequestBuilder {
        var copy = self
        let existing = buildURLRequest
        copy.buildURLRequest = { request in
            existing(&request)
            modifyURLRequest(&request)
        }
        return copy
    }
}

// MARK: HTTP Header
private extension RequestBuilder {
    func httpHeader(name: String, value: String) -> RequestBuilder {
        modifyRequest { $0.addValue(value, forHTTPHeaderField: name) }
    }
}

// MARK: State / Type
// MARK: HTTP Method
extension RequestBuilder {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case head = "HEAD"
        case delete = "DELETE"
        case patch = "PATCH"
        case options = "OPTIONS"
        case connect = "CONNECT"
        case trace = "TRACE"
    }
}

// MARK: Content Type
struct ContentType {
    static let header = HeaderName(rawValue: "Content-Type")

    var rawValue: String

    // MARK: - Application
    public static let applicationJSON = ContentType(rawValue: "application/json")
    public static let applicationOctetStream = ContentType(rawValue: "application/octet-stream")
    public static let applicationXML = ContentType(rawValue: "application/xml")
    public static let applicationZip = ContentType(rawValue: "application/zip")
    public static let applicationXWwwFormUrlEncoded = ContentType(rawValue: "application/x-www-form-urlencoded")

    // MARK: - Image
    public static let imageGIF = ContentType(rawValue: "image/gif")
    public static let imageJPEG = ContentType(rawValue: "image/jpeg")
    public static let imagePNG = ContentType(rawValue: "image/png")
    public static let imageTIFF = ContentType(rawValue: "image/tiff")

    // MARK: - Text
    public static let textCSS = ContentType(rawValue: "text/css")
    public static let textCSV = ContentType(rawValue: "text/csv")
    public static let textHTML = ContentType(rawValue: "text/html")
    public static let textPlain = ContentType(rawValue: "text/plain")
    public static let textXML = ContentType(rawValue: "text/xml")

    // MARK: - Video
    public static let videoMPEG = ContentType(rawValue: "video/mpeg")
    public static let videoMP4 = ContentType(rawValue: "video/mp4")
    public static let videoQuicktime = ContentType(rawValue: "video/quicktime")
    public static let videoXMsWmv = ContentType(rawValue: "video/x-ms-wmv")
    public static let videoXMsVideo = ContentType(rawValue: "video/x-msvideo")
    public static let videoXFlv = ContentType(rawValue: "video/x-flv")
    public static let videoWebm = ContentType(rawValue: "video/webm")

    // MARK: - Multipart Form Data
    static func multipartFormData(boundary: String) -> ContentType {
        ContentType(rawValue: "multipart/form-data; boundary=\(boundary)")
    }
}

// MARK: Header Name
struct HeaderName {
    var rawValue: String

    static let userAgent: HeaderName = "User-Agent"
    static let cookie: HeaderName = "Cookie"
    static let authorization: HeaderName = "Authorization"
    static let accept: HeaderName = "Accept"
    static let contentLength: HeaderName = "Content-Length"

    static let contentType = ContentType.header
    static let contentEncoding = RequestBuilder.Encoding.contentEncodingHeader
    static let acceptEncoding = RequestBuilder.Encoding.acceptEncodingHeader
}

extension HeaderName: ExpressibleByStringLiteral {
    init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

extension RequestBuilder {
    func contentType(_ contentType: ContentType) -> RequestBuilder {
        header(name: ContentType.header, value: contentType.rawValue)
    }

    func accept(_ contentType: ContentType) -> RequestBuilder {
        header(name: .accept, value: contentType.rawValue)
    }

    enum Encoding: String {
        case gzip
        case compress
        case deflate
        case br

        static let contentEncodingHeader = HeaderName(rawValue: "Content-Encoding")
        static let acceptEncodingHeader = HeaderName(rawValue: "Accept-Encoding")
    }

    func contentEncoding(_ encoding: Encoding) -> RequestBuilder {
        header(name: Encoding.contentEncodingHeader, value: encoding.rawValue)
    }

    func acceptEncoding(_ encoding: Encoding) -> RequestBuilder {
        header(name: Encoding.acceptEncodingHeader, value: encoding.rawValue)
    }
}

// MARK: Base URL
/*
 CAUTION:
 if you get weird errors, make sure that your base URL does not have a “/”
 at the end, and that your path does not contain “/” at the start.
 */
private extension RequestBuilder.RequestConfiguration {
    static func baseURL(_ baseURL: URL) -> RequestBuilder.RequestConfiguration {
        return RequestBuilder.RequestConfiguration { request in
            let finalURL = request.urlComponents.url(relativeTo: baseURL) ?? baseURL

            var urlRequest = URLRequest(url: finalURL)
            request.buildURLRequest(&urlRequest)

            return urlRequest
        }
    }
}
