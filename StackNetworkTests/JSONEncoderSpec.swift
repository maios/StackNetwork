//
//  JSONEncoderSpec.swift
//  StackNetworkTests
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import StackNetwork

class JSONEncoderSpec: QuickSpec {

    override func spec() {
        var sut: JSONEncoder!
        var requestToEncode: URLRequest!

        beforeEach {
            sut = JSONEncoder()
            requestToEncode = URLRequest(url: URL(string: "https://dummy.org")!)
        }

        describe("A JSONEncoder instance") {
            var cat: Cat!

            beforeEach {
                cat = Cat(name: "Mai")
            }

            it("will throw an error if the encodable value fails to encode") {
                cat.isGoodBoi = false
                expect { try sut.encode(requestToEncode, with: cat) }.to(throwError(Cat.Error.catBeingCat))
            }

            describe("when successfully encode the given value") {

                it("will set correct value to request body") {
                    let encodedRequest = try! sut.encode(requestToEncode, with: cat)
                    expect(String(data: encodedRequest.httpBody!, encoding: .utf8)) == "{\"name\":\"Mai\"}"
                }

                it("will set correct value for Content-Type header if none") {
                    requestToEncode.setValue(nil, forHTTPHeaderField: "Content-Type")
                    let encodedRequest = try! sut.encode(requestToEncode, with: cat)
                    expect(encodedRequest.value(forHTTPHeaderField: "Content-Type")) == "application/json"
                }

                it("will not set value for Content-Type header if exists") {
                    requestToEncode.setValue("some", forHTTPHeaderField: "Content-Type")
                    let encodedRequest = try! sut.encode(requestToEncode, with: cat)
                    expect(encodedRequest.value(forHTTPHeaderField: "Content-Type")) == "some"
                }
            }
        }
    }
}
