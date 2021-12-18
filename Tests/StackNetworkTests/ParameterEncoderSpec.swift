//
//  ParameterEncoderSpec.swift
//  StackNetworkTests
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Quick
import Nimble
@testable import StackNetwork

class ParameterEncoderSpec: QuickSpec {

    override func spec() {
        var sut: ParameterEncoder!
        var requestToEncode: URLRequest!

        beforeEach {
            requestToEncode = URLRequest(url: URL(string: "https://dummy.org")!)
        }

        describe("A default ParameterEncoder instance") {
            beforeEach {
                sut = ParameterEncoder.default
            }

            it("will not encode a nil parameters") {
                expect(try! sut.encode(requestToEncode, with: nil)) == requestToEncode
            }

            it("will not encode an empty parameters") {
                expect(try! sut.encode(requestToEncode, with: [:])) == requestToEncode
            }

            it("can encode a string value") {
                let encodeRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                expect(encodeRequest.url!.absoluteString) == "https://dummy.org?foo=bar"
            }

            it("can encode a dictionary") {
                let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": ["bar": 1]])
                expect(encodedRequest.url!.absoluteString) == "https://dummy.org?foo%5Bbar%5D=1"
            }

            it("can encode a nested dictionary") {
                let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": ["bar": ["baz": ["a", true]]]])
                expect(encodedRequest.url!.absoluteString) == """
                    https://dummy.org?foo%5Bbar%5D%5Bbaz%5D%5B%5D=a&foo%5Bbar%5D%5Bbaz%5D%5B%5D=1
                    """
            }

            describe("can throw error") {
                context("when encode a request that is missing url") {
                    beforeEach {
                        requestToEncode.url = nil
                    }
                    it("will throw URLRequestEncodingError.missingURL") {
                        let error = URLRequestEncodingError.missingURL
                        expect { try sut.encode(requestToEncode, with: ["dummyKey": 1]) }.to(throwError(error))
                    }
                }

                context("when encode a request with malformed url") {
                    beforeEach {
                        requestToEncode.url = URL(string: "https://dummy.org:-80")
                    }
                    it("will throw URLRequestEncodingError.invalidURL") {
                        let error = URLRequestEncodingError.invalidURL
                        expect { try sut.encode(requestToEncode, with: ["dummyKey": 1]) }.to(throwError(error))
                    }
                }
            }
        }

        // MARK: - Encode destination

        describe("A ParameterEncoder instance can encode data") {
            context("if destination is to query string") {
                beforeEach {
                    sut = ParameterEncoder.queryString
                }
                it("it will create query string for the request") {
                    let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                    expect(encodedRequest.url!.absoluteString) == "https://dummy.org?foo=bar"
                }
                it("it will append values to an existing query string") {
                    var urlComponents = URLComponents(url: requestToEncode.url!, resolvingAgainstBaseURL: false)
                    urlComponents?.query = "dummy=dummier"
                    requestToEncode.url = urlComponents?.url

                    let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                    expect(encodedRequest.url!.absoluteString) == "https://dummy.org?dummy=dummier&foo=bar"
                }
            }

            context("if destination is to request body") {
                beforeEach {
                    sut = ParameterEncoder.httpBody
                }
                it("it will encode data to request body") {
                    let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                    expect(String(data: encodedRequest.httpBody!, encoding: .utf8)) == "foo=bar"
                }
            }
        }

        // MARK: - Encode boolean

        describe("A ParameterEncoder instance can encode boolean value") {
            context("if the encoding option is as numeric value") {
                beforeEach {
                    sut = ParameterEncoder(boolEncoding: .numeric)
                }
                it("boolean value will be expressed with 0 or 1") {
                    let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": true])
                    expect(encodedRequest.url!.absoluteString) == "https://dummy.org?foo=1"
                }
            }

            context("if the encoding option is as string literal") {
                beforeEach {
                    sut = ParameterEncoder(boolEncoding: .literal)
                }
                it("boolean value will be expressed with true or false") {
                    let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": true])
                    expect(encodedRequest.url!.absoluteString) == "https://dummy.org?foo=true"
                }
            }
        }

        // MARK: - Array

        describe("A ParameterEncoder instance can encode array") {
            context("if array encode option is with brackets") {
                beforeEach {
                    sut = ParameterEncoder(arrayEncoding: .brackets)
                }
                it("query items will have enclosed square brackets") {
                    let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": ["bar", 1, 2.5, true]])
                    expect(encodedRequest.url!.absoluteString) == """
                        https://dummy.org?foo%5B%5D=bar&foo%5B%5D=1&foo%5B%5D=2.5&foo%5B%5D=1
                        """
                }
            }

            context("if array encode option is without brackets") {
                beforeEach {
                    sut = ParameterEncoder(arrayEncoding: .noBrackets)
                }
                it("query items will not have enclosed square brackets") {
                    let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": ["bar", 1, 2.5, true]])
                    expect(encodedRequest.url!.absoluteString) == "https://dummy.org?foo=bar&foo=1&foo=2.5&foo=1"
                }
            }
        }

        // MARK: - Percent encoding

        describe("A ParameterEncoder instance can encode special string characters") {
            beforeEach {
                sut = ParameterEncoder.default
            }

            it("all reserved characters except 'question mark' and 'slash' will be percent escaped") {
                let generalDelimiters = ":#[]@"
                let subDelimiters = "!$&'()*+,;="
                let parameters = ["reserved": "\(generalDelimiters)\(subDelimiters)"]

                let encodedRequest = try! sut.encode(requestToEncode, with: parameters)
                expect(encodedRequest.url!.absoluteString) == """
                    https://dummy.org?reserved=%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D
                    """
            }

            it("'question mark' and 'slash' will be kept as it") {
                let encodedRequest = try! sut.encode(requestToEncode, with: ["reserved": "?/"])
                expect(encodedRequest.url!.absoluteString) == "https://dummy.org?reserved=?/"
            }

            it("illegal ASCII characters will be percent escaped") {
                let encodedRequest = try! sut.encode(requestToEncode, with: ["illegal": " \"#%<>[]\\^`{}|"])
                expect(encodedRequest.url!.absoluteString) == """
                    https://dummy.org?illegal=%20%22%23%25%3C%3E%5B%5D%5C%5E%60%7B%7D%7C
                    """
            }

            it("Non-Latin characters will be percent escaped") {
                let parameters = ["nonLatin": [["french": "français"],
                                               ["japanese": "日本語"],
                                               ["arabic": "العربية"],
                                               ["emoji": "😃"]]]
                let encodedRequest = try! sut.encode(requestToEncode, with: parameters)
                expect(encodedRequest.url!.absoluteString) == "https://dummy.org?"
                    + "nonLatin%5B%5D%5Bfrench%5D=fran%C3%A7ais&"
                    + "nonLatin%5B%5D%5Bjapanese%5D=%E6%97%A5%E6%9C%AC%E8%AA%9E&"
                    + "nonLatin%5B%5D%5Barabic%5D=%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9&"
                    + "nonLatin%5B%5D%5Bemoji%5D=%F0%9F%98%83"
            }
        }

        // MARK: - HTTP Method

        describe("A ParameterEncoder type can decide encode destination") {
            beforeEach {
                sut = ParameterEncoder(destination: .methodDependent)
            }

            it("GET request will have parameters appended to the query string") {
                requestToEncode.httpMethod = "GET"

                let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                expect(encodedRequest.url!.absoluteString) == "https://dummy.org?foo=bar"
                expect(encodedRequest.httpBody).to(beNil())
                expect(encodedRequest.value(forHTTPHeaderField: "Content-Type")).to(beNil())
            }

            it("DELET request will have parameters appended to the query string") {
                requestToEncode.httpMethod = "DELETE"

                let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                expect(encodedRequest.url!.absoluteString) == "https://dummy.org?foo=bar"
                expect(encodedRequest.httpBody).to(beNil())
                expect(encodedRequest.value(forHTTPHeaderField: "Content-Type")).to(beNil())
            }

            it("POST request will have parameters encoded to request body") {
                requestToEncode.httpMethod = "POST"

                let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                expect(encodedRequest.url!.query).to(beNil())
                expect(String(data: encodedRequest.httpBody!, encoding: .utf8)) == "foo=bar"
                expect(encodedRequest.value(forHTTPHeaderField: "Content-Type")) == "application/x-www-form-urlencoded; charset=utf-8"
            }

            it("PUT request will have parameters encoded to request body") {
                requestToEncode.httpMethod = "PUT"

                let encodedRequest = try! sut.encode(requestToEncode, with: ["foo": "bar"])
                expect(encodedRequest.url!.query).to(beNil())
                expect(String(data: encodedRequest.httpBody!, encoding: .utf8)) == "foo=bar"
                expect(encodedRequest.value(forHTTPHeaderField: "Content-Type")) == "application/x-www-form-urlencoded; charset=utf-8"
            }
        }
    }
}
