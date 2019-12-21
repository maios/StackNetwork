//
//  NetworkProviderSpec.swift
//  StackNetworkTests
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Quick
import Nimble

@testable import StackNetwork

class NetworkProviderSpec: QuickSpec {

    override func spec() {
        var sut: NetworkProvider<GitHub>!
        var stubBehavior: NetworkProvider<GitHub>.StubBehaviorClosure!

        describe("A NetworkProvider instance can stub success") {
            beforeEach {
                stubBehavior = { target in .immediate(TestHelper.stubSuccess(target: target)) }
                sut = NetworkProvider<GitHub>(stubBehavior: stubBehavior)
            }

            it("and complete with stubbed response for zen request") {
                waitUntil { done in
                    _ = sut.request(.zen) { result in
                        switch result {
                        case .success(let response):
                            expect(String(data: response.data, encoding: .utf8)) == """
                                Half measures are as bad as nothing at all.
                                """
                            expect(response.request).toNot(beNil())
                            done()
                            
                        case .failure:
                            fail("Unexpected error occured!")
                        }
                    }
                }
            }

            it("and complete with stubbed response for user profile request") {
                waitUntil { done in
                    _ = sut.request(.userProfile("Mai")) { result in
                        switch result {
                        case .success(let response):
                            expect(String(data: response.data, encoding: .utf8)) == """
                                {\"login\": \"Mai\", \"id\": 100}
                                """
                            expect(response.request).toNot(beNil())
                            done()

                        case .failure:
                            fail("Unexpected error occured!")
                        }
                    }
                }
            }
        }

        describe("A NetworkProvider instance can stub failure") {
            var stubbedError: URLError!
            beforeEach {
                stubbedError = URLError(.networkConnectionLost)
                stubBehavior = { target in .immediate(TestHelper.stubFailure(target: target, error: stubbedError)) }
                sut = NetworkProvider<GitHub>(stubBehavior: stubBehavior)
            }

            it("it will complete with stubbed error") {
                waitUntil { done in
                    _ = sut.request(.zen) { result in
                        switch result {
                        case .failure(let error):
                            expect(error as? URLError) == stubbedError
                            done()
                        case .success: fail("Expect request to fail!")
                        }
                    }
                }
            }
        }

        describe("A NetworkProvider instance with delayed stubs") {
            beforeEach {
                stubBehavior = { target in .delay(seconds: 1, response: TestHelper.stubSuccess(target: target)) }
                sut = NetworkProvider<GitHub>(stubBehavior: stubBehavior)
            }

            it("will delay completion") {
                let startDate = Date()
                waitUntil(timeout: 2) { done in
                    _ = sut.request(.zen) { _ in
                        expect(Date().timeIntervalSince(startDate)) >= 1
                        done()
                    }
                }
            }
        }
    }
}
