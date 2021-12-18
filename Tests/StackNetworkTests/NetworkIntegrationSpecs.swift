//
//  NetworkIntegrationSpecs.swift
//  StackNetworkTests
//
//  Created by Mai Mai on 12/22/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs

@testable import StackNetwork

class NetworkIntegrationSpecs: QuickSpec {

    override func spec() {
        var sut: NetworkProvider<GitHub>!

        beforeEach {
            sut = NetworkProvider<GitHub>()

            OHHTTPStubs.stubRequests(passingTest: isPath("/users/good_cat")) { _ -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(data: GitHub.userProfile("good_cat").sampleData, statusCode: 200, headers: nil)
            }
            OHHTTPStubs.stubRequests(passingTest: isPath("/users/bad_cat")) { _ -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(data: GitHub.userProfile("bad_cat").sampleData, statusCode: 404, headers: nil)
            }
        }

        afterEach {
            OHHTTPStubs.removeAllStubs()
        }

        describe("A NetworkProvider instance when completed") {
            beforeEach {
                OHHTTPStubs.stubRequests(passingTest: isPath("/zen")) { _ -> OHHTTPStubsResponse in
                    return OHHTTPStubsResponse(error: URLError(.networkConnectionLost)).responseTime(1)
                }
            }

            it("will return correct data with success status code") {
                waitUntil { done in
                    _ = sut.request(.userProfile("good_cat")) { result in
                        expect { try result.get().data } == GitHub.userProfile("good_cat").sampleData
                        done()
                    }
                }
            }

            it("will return correct data with failure status code") {
                waitUntil { done in
                    _ = sut.request(.userProfile("bad_cat")) { result in
                        expect { try result.get().statusCode } == 404
                        done()
                    }
                }
            }

            it("will return error if network fails") {
                waitUntil(timeout: 2) { done in
                    _ = sut.request(.zen) { result in
                        expect(result.isSuccess).to(beFalse())
                        done()
                    }
                }
            }

            it("will return error if request is cancelled") {
                waitUntil(timeout: 2) { done in
                    let request = sut.request(.zen) { result in
                        if case let .failure(error as URLError) = result {
                            expect(error.code) == .cancelled
                            done()
                        }
                    }
                    request.cancel()
                }
            }
        }

        describe("A NetworkProvider instance will inform adapter before request is sent") {
            context("if adapter passes") {
                var requestIsAdapted = false

                beforeEach {
                    let requestAdapter: RequestAdapterClosure = { request in
                        requestIsAdapted = true
                        return request
                    }
                    sut = NetworkProvider<GitHub>(requestAdapter: requestAdapter)
                }
                it("request will be sent") {
                    waitUntil { done in
                        _ = sut.request(.userProfile("good_cat")) { _ in
                            expect(requestIsAdapted) == true
                            done()
                        }
                    }
                }
            }
            context("if adaption fails") {
                beforeEach {
                    let requestAdapter: RequestAdapterClosure = { request in
                        throw TestError.some
                    }
                    sut = NetworkProvider<GitHub>(requestAdapter: requestAdapter)
                }
                it("request will fail immediately") {
                    waitUntil { done in
                        _ = sut.request(.userProfile("good_cat")) { result in
                            expect(result.isSuccess).to(beFalse())
                            done()
                        }
                    }
                }
            }
        }

        describe("A NetworkProvider instance") {

            class TestNetworkPlugin: PluginType {
                var request: Requestable?
                var result: Result<Response, Error>?

                func willSend(_ request: Requestable) {
                    self.request = request
                }

                func didReceive(_ result: Result<Response, Error>, request: Requestable) {
                    self.result = result
                }
            }

            var plugin: TestNetworkPlugin!

            beforeEach {
                plugin = TestNetworkPlugin()
                sut = NetworkProvider<GitHub>(plugins: [plugin])
            }

            it("will inform plugins before request is sent") {
                waitUntil(timeout: 2) { done in
                    _ = sut.request(.zen) { _ in
                        expect(plugin.request?.urlRequest.url?.absoluteString) == "https://api.github.com/zen"
                        done()
                    }
                }
            }
            it("will inform plugins when result is received") {
                waitUntil(timeout: 2) { done in
                    _ = sut.request(.zen) { _ in
                        expect(plugin.result).toNot(beNil())
                        done()
                    }
                }
            }
        }

        describe("A NetworkProvider instance") {
            var requestCount = 0

            beforeEach {
                var iterationCount = 0
                OHHTTPStubs.stubRequests(passingTest: isPath("/zen")) { _ -> OHHTTPStubsResponse in
                    iterationCount += 1
                    switch iterationCount {
                    case 1: return OHHTTPStubsResponse(error: URLError(.networkConnectionLost)).responseTime(1)
                    default: return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                    }
                }
            }

            afterEach {
                requestCount = 0
            }

            describe("when retry behavior is not to retry") {
                beforeEach {
                    let retryBehavior: RetryBehaviorClosure = { (_, _) in
                        return .doNotRetry
                    }
                    let requestAdapter: RequestAdapterClosure = { request in
                        requestCount += 1
                        return request
                    }
                    sut = NetworkProvider<GitHub>(requestAdapter: requestAdapter, retryBehavior: retryBehavior)
                }

                it("will not retry requests if failed") {
                    waitUntil(timeout: 2) { done in
                        _ = sut.request(.zen) { _ in
                            expect(requestCount) == 1
                            done()
                        }
                    }
                }
            }

            describe("can retry request") {
                beforeEach {
                    let retryBehavior: RetryBehaviorClosure = { (_, _) in
                        return .retryWithDelay(2)
                    }
                    let requestAdapter: RequestAdapterClosure = { request in
                        requestCount += 1
                        return request
                    }
                    sut = NetworkProvider<GitHub>(requestAdapter: requestAdapter, retryBehavior: retryBehavior)
                }

                it("it will adapt request everytime it is retried") {
                    waitUntil(timeout: 4) { done in
                        _ = sut.request(.zen) { _ in
                            expect(requestCount) > 1
                            done()
                        }
                    }
                }

                it("it will retry with given delay interval") {
                    let startDate = Date()
                    waitUntil(timeout: 4) { done in
                        _ = sut.request(.zen, completion: { _ in
                            expect(Date().timeIntervalSince(startDate)) >= 2
                            done()
                        })
                    }
                }
            }
        }
    }
}
