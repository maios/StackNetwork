//
//  JSONDecodeSpec.swift
//  StackNetworkTests
//
//  Created by Mai Mai on 12/23/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Quick
import Nimble

@testable import StackNetwork

class JSONDecoderSpec: QuickSpec {

    override func spec() {

        describe("A default JSONDecoder") {
            var sut: JSONDecoder!
            var data: Data!

            beforeEach {
                sut = JSONDecoder()
            }

            describe("is given a key path") {

                context("if key path exists and data is valid") {
                    beforeEach {
                        data = TestHelper.getTestMovie()
                    }
                    it("will decode string value for movie title") {
                        expect { try sut.decode(String.self, from: data, atKeyPath: "title") } == "My Neighbor Totoro"
                    }
                    it("will decode number value for movie duration") {
                        expect { try sut.decode(TimeInterval.self, from: data, atKeyPath: "duration") } == 5220
                    }
                    it("will decode url value for movie url") {
                        let expectedURL = URL(string: "https://ghibliapi.herokuapp.com/films/58611129-2dbc-4a81-a72f-77ddfc1b1b49")!
                        expect { try sut.decode(URL.self, from: data, atKeyPath: "url") } == expectedURL
                    }
                    it("will decode array value for movie characters") {
                        expect { try sut.decode([MovieCharacter].self, from: data, atKeyPath: "characters") } == [
                            MovieCharacter(id: "986faac6-67e3-4fb8-a9ee-bad077c2e7fe",
                                           name: "Satsuki Kusakabe",
                                           gender: "Female",
                                           age: 11),
                            MovieCharacter(id: "d5df3c04-f355-4038-833c-83bd3502b6b9",
                                           name: "Mei Kusakabe",
                                           gender: "Female",
                                           age: 4),
                        ]
                    }

                    it("will decode value with nested keypath for rotten tomatoes score") {
                        expect { try sut.decode(Double.self, from: data, atKeyPath: "score.rotten_tomatoes") } == 93
                    }
                }

                context("if key path does not exists") {
                    beforeEach {
                        data = "{\"something\": \"some\"}".data(using: .utf8)
                    }
                    it("will throw error if it fails on empty data") {
                        expect { try sut.decode(String.self, from: data, atKeyPath: "something_else") }.to(throwError())
                    }
                    it("will return an empty value if it does not fail on empty data") {
                        expect { try sut.decode([String: String].self,
                                                from: data,
                                                atKeyPath: "something_else",
                                                failsOnEmptyData: false) } == [:]
                    }
                }
            }
        }
    }
}
