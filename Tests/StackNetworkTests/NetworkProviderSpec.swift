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
        var stubBehavior: StubBehaviorClosure<GitHub>!

        describe("A NetworkProvider instance can stub success") {
            beforeEach {
                stubBehavior = { target in .immediate(TestHelper.stubSampleResponse(target: target)) }
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
            var stubError: URLError!
            beforeEach {
                stubError = URLError(.networkConnectionLost)
                stubBehavior = { target in .immediate(TestHelper.stubSampleResponse(target: target, error: stubError)) }
                sut = NetworkProvider<GitHub>(stubBehavior: stubBehavior)
            }

            it("it will complete with stubbed error") {
                waitUntil { done in
                    _ = sut.request(.zen) { result in
                        switch result {
                        case .failure(let error):
                            expect(error as? URLError) == stubError
                            done()
                        case .success: fail("Expect request to fail!")
                        }
                    }
                }
            }
        }

        describe("A NetworkProvider instance with delayed stubs") {
            beforeEach {
                stubBehavior = { target in .delay(seconds: 1, response: TestHelper.stubSampleResponse(target: target)) }
                sut = NetworkProvider<GitHub>(stubBehavior: stubBehavior)
            }

            it("will delay completion") {
                let startDate = Date()
                waitUntil(timeout: .seconds(2)) { done in
                    _ = sut.request(.zen) { _ in
                        expect(Date().timeIntervalSince(startDate)) >= 1
                        done()
                    }
                }
            }
        }

        describe("A NetworkProvider instance") {
            var defaultQueue: DispatchQueue!

            beforeEach {
                defaultQueue = DispatchQueue(label: "com.maimai.StackNetwork.tests.default-queue")
                sut = NetworkProvider<GitHub>(callbackQueue: defaultQueue)
            }

            it("will use default queue if none specified when making request") {
                waitUntil { done in
                    _ = sut.request(.userProfile("good_cat")) { _ in
                        expect { dispatchPrecondition(condition: .onQueue(defaultQueue)) }.toNot(throwAssertion())
                        done()
                    }
                }
            }

            it("will use custom queue if specified when making request") {
                waitUntil { done in
                    let otherQueue = DispatchQueue(label: "com.maimai.StackNetwork.tests.some-queue")
                    _ = sut.request(.userProfile("good_cat"), callbackQueue: otherQueue) { _ in
                        expect { dispatchPrecondition(condition: .onQueue(otherQueue)) }.toNot(throwAssertion())
                        done()
                    }
                }
            }
        }
    }
}
