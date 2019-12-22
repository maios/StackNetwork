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
            OHHTTPStubs.stubRequests(passingTest: isPath("/zen")) { _ -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(error: URLError(.networkConnectionLost)).responseTime(1)
            }
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
                    let requestAdapter: NetworkProvider.RequestAdapterClosure = { request in
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
                    let requestAdapter: NetworkProvider.RequestAdapterClosure = { request in
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
    }
}
