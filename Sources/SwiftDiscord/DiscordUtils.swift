// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import Dispatch
import Foundation

enum Either<L, R> {
    case left(L)
    case right(R)
}

extension Dictionary {
    func get<T>(_ value: Key, or default: T) -> T {
        return self[value] as? T ?? `default`
    }

    func get<T>(_ value: Key, as type: T.Type) -> T? {
        return self[value] as? T
    }
}

extension Dictionary where Key == String {
    func getSnowflake(key: String = "id") -> Snowflake {
        return Snowflake(self[key] as? String) ?? 0
    }
}

extension String {
    var snakecase: String {
        var ret = ""

        for index in characters.indices {
            let stringChar = String(self[index])

            if stringChar.uppercased() == stringChar {
                if index != startIndex {
                    ret += "_"
                }

                ret += stringChar.lowercased()
            } else {
                ret += stringChar
            }
        }

        return ret
    }
}

extension URL {
    static let localhost = URL(string: "http://localhost/")!
}

func createMultipartBody(json: [String: Any], files: [DiscordFileUpload]) -> (boundary: String, body: Data) {
    let boundary = "Boundary-\(UUID())"
    let crlf = "\r\n".data(using: .utf8)!
    var body = Data()

    let encodedJson = JSON.encodeJSONData(json) ?? Data()

    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"payload_json\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: application/json\r\n".data(using: .utf8)!)
    body.append("Content-Length: \(encodedJson.count)\r\n\r\n".data(using: .utf8)!)
    body.append(encodedJson)
    body.append(crlf)

    for (index, file) in files.enumerated() {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\(index)\"; filename=\"\(file.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(file.mimeType)\r\n".data(using: .utf8)!)
        body.append("Content-Length: \(file.data.count)\r\n\r\n".data(using: .utf8)!)
        body.append(file.data)
        body.append(crlf)
    }

    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    return (boundary, body)
}

class DiscordDateFormatter {
    private static let formatter = DiscordDateFormatter()

    private let RFC3339DateFormatter = DateFormatter()

    private init() {
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        RFC3339DateFormatter.locale = Locale(identifier: "en_US")
    }

    static func format(_ string: String) -> Date? {
        return formatter.RFC3339DateFormatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        return formatter.RFC3339DateFormatter.string(from: date)
    }
}

protocol Lockable {
    var lock: DispatchSemaphore { get }

    func protected(_ block: () -> ())
    func get<T>(_ getter: @autoclosure () -> T) -> T
}

extension Lockable {
    func protected(_ block: () -> ()) {
        lock.wait()
        block()
        lock.signal()
    }

    func get<T>(_ getter: @autoclosure () -> T) -> T {
        defer { lock.signal() }

        lock.wait()

        return getter()
    }
}
