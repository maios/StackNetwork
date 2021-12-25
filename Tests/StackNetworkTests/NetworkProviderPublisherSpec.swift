import Quick
import Nimble
import OHHTTPStubs

@testable import StackNetwork

#if canImport(Combine)
import Combine

@available(iOS 13.0, *)
class NetworkProviderPublisherSpec: QuickSpec {

    override func spec() {
        var sut: NetworkProvider<GitHub>!
        var subscription: Combine.AnyCancellable?

        afterEach {
            subscription?.cancel()
            subscription = nil
        }

        describe("A network provider") {

            beforeEach {
                let stubBehavior: StubBehaviorClosure = { target in .immediate(TestHelper.stubSampleResponse(target: target)) }
                sut = NetworkProvider<GitHub>(stubBehavior: stubBehavior)
            }

            it("emits one and only one Response object") {
                var numberOfEvents = 0

                waitUntil { done in
                    subscription = sut.requestPublisher(.zen)
                        .sink(
                            receiveCompletion: { completion in
                                switch completion {
                                case .failure(let error): fail("Unexpected error: \(error)")
                                case .finished: done()
                                }
                            },
                            receiveValue: { _ in numberOfEvents += 1 }
                        )
                }
                expect(numberOfEvents).to(equal(1))
            }

            it("emits stubbed data for zen request") {
                waitUntil { done in
                    let target = GitHub.zen
                    subscription = sut.requestPublisher(target)
                        .sink(
                            receiveCompletion: { completion in
                                switch completion {
                                case .failure(let error): fail("Unexpected error: \(error)")
                                case .finished: done()
                                }
                            },
                            receiveValue: { response in
                                expect(response.data).to(equal(target.sampleData))
                            }
                        )
                }
            }
        }
    }
}
#endif
