@testable import Async
import XCTest

final class AsyncTests: XCTestCase {
    let worker: Worker = EmbeddedEventLoop()
    func testVariadicMap() throws {
        let futureA = Future.map(on: worker) { "a" }
        let futureB = Future.map(on: worker) { "b" }
        let futureAB = map(to: String.self, futureA, futureB) { a, b in
            return "\(a)\(b)"
        }
        try XCTAssertEqual(futureAB.wait(), "ab")
    }

    func testFlatten() throws {
        let loop = EmbeddedEventLoop()
        let a = loop.newPromise(String.self)
        let b = loop.newPromise(String.self)
        let arr: [Future<String>] = [a.futureResult, b.futureResult]
        let flat = arr.flatten(on: loop)
        a.succeed(result: "a")
        b.succeed(result: "b")
        try XCTAssertEqual(flat.wait(), ["a", "b"])
    }

    func testFlattenStackOverflow() throws {
        let loop = EmbeddedEventLoop()
        var arr: [Future<Int>] = []
        let count = 1<<12
        for i in 0..<count {
            arr.append(loop.newSucceededFuture(result: i))
        }
        try XCTAssertEqual(arr.flatten(on: loop).wait().count, count)
    }

    func testFlattenFail() throws {
        let loop = EmbeddedEventLoop()
        let a = loop.newPromise(String.self)
        let b = loop.newPromise(String.self)
        let arr: [Future<String>] = [a.futureResult, b.futureResult]
        a.succeed(result: "a")
        b.fail(error: "b")
        XCTAssertThrowsError(try arr.flatten(on: loop).wait()) { XCTAssert($0 is String) }
    }

    func testFlattenEmpty() throws {
        let loop = EmbeddedEventLoop()
        let arr: [Future<String>] = []
        try XCTAssertEqual(arr.flatten(on: loop).wait().count, 0)
    }
    
    func testTransform() throws {
        let future = Future.map(on: worker) { 1 }
        let transformed = future.transform(to: "a")
        try XCTAssertEqual("a", transformed.wait())
    }
    
    func testTransformAlways() throws {
        let loop = EmbeddedEventLoop()
        let a = loop.newPromise(String.self)
        let b = loop.newPromise(String.self)
        let futureA = a.futureResult
        let futureB = b.futureResult
        a.succeed(result: "a")
        b.fail(error: "b")
        let transformSucceed = try futureA.transformAlways(to: 1).wait()
        let transformFail = try futureB.transformAlways(to: 1).wait()
        XCTAssertEqual(transformSucceed, transformFail)
        XCTAssertEqual(transformSucceed, 1)
    }
    
    static let allTests = [
        ("testVariadicMap", testVariadicMap),
        ("testFlatten", testFlatten),
        ("testFlattenStackOverflow", testFlattenStackOverflow),
        ("testFlattenFail", testFlattenFail),
        ("testFlattenEmpty", testFlattenEmpty),
    ]
}

extension String: Error { }
