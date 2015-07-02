//
//  sync.swift
//  Safe
//
//  Created by Josh Baker on 7/1/15.
//  Copyright © 2015 ONcast. All rights reserved.
//

import XCTest

func now() -> NSTimeInterval {
    return NSDate().timeIntervalSince1970
}
func makeTotal(count: Int) -> Int {
    var res = 0
    for var i = 0; i < count; i++ {
        res += i
    }
    return res
}

extension Tests {
    
    /// WaitGroup testing
    func _testWaitGroup(count: Int, individualAdds: Bool){
        let total = IntA(0)
        let xtotal = makeTotal(count)

        let wg = WaitGroup()
        if !individualAdds {
            wg.add(count)
        }
        for var i = 0; i < count; i++ {
            if individualAdds {
                wg.add(1)
            }
            { i in
                dispatch {
                    total += i
                    wg.done()
                }
            }(i)
        }
        wg.wait()
        XCTAssert(xtotal == total, "The expected total is incorrect. xtotal: \(xtotal), total: \(total)")
    }
    func testWaitGroupZero() {
        _testWaitGroup(0, individualAdds: false)
    }
    func testWaitGroupTen() {
        _testWaitGroup(10, individualAdds: false)
    }
    func testWaitGroupHundred() {
        _testWaitGroup(100, individualAdds: false)
    }
    func testWaitGroupIndividualAdds() {
        _testWaitGroup(100, individualAdds: true)
    }
    func testWaitGroupNegative() {
        let ex = _try({
            self._testWaitGroup(-100, individualAdds: false)
        })
        XCTAssert(ex != nil, "Negative WaitGroup should fail.")
    }

    /// Once testing
    func testOnce() {
        let total = IntA(0)
        let once = Once()
        for var i = 0; i < 100; i++ {
            once.doit {
                total++
            }
        }
        XCTAssert(total == 1, "Once.doit should only run once.")
    }
   
    /// Mutex testing
    func testMutexSimpleLock() {
        let mutex = Mutex()
        mutex.lock()
        mutex.unlock()
    }
    func testMutexClosure() {
        var result = 0
        let mutex = Mutex()
        mutex.lock {
            result = 1
        }
        XCTAssert(result == 1, "Result should equal One.")
    }
    func testMutexDispatch() {
        let count = 100
        var total = 0
        let xtotal = makeTotal(count)

        let wg = WaitGroup()
        let mutex = Mutex()
        wg.add(count)
        for var i = 0; i < count; i++ {
            { i in
                dispatch {
                    mutex.lock()
                    total += i
                    mutex.unlock()
                    wg.done()
                }
            }(i)
        }
        wg.wait()
        XCTAssert(xtotal == total, "The expected total is incorrect. xtotal: \(xtotal), total: \(total)")
    }
    

    /// Cond testing
    func testCondSignal() {
        var value = "1"
        let cond = Cond(Mutex())
        dispatch{
            cond.mutex.lock()
            value += "2"
            cond.signal()
            cond.mutex.unlock()
        }
        cond.mutex.lock()
        while value != "12" {
            cond.wait()
        }
        cond.mutex.unlock()
        value += "3"
        XCTAssert(value == "123", "Expecting the value to be '123'. Got \(value)")
    }
    func testCondTimeout() {
        let cond = Cond(Mutex())
        let start = now()
        cond.wait(0.10)
        XCTAssert(now() - start > 0.10, "Wait returned too quickly")
    }

    func _testCondBroadcast(count: Int) {
        var done = false
        let total = IntA(0)
        let xtotal = makeTotal(count)
        let cond = Cond(Mutex())
        let wg = WaitGroup()
        
        let f = { (i: Int)->Void in
            dispatch {
                cond.mutex.lock {
                    while !done {
                        cond.wait()
                    }
                }
                total += i // should be atomic
                wg.done()
            }
        }
        wg.add(count)
        for var i = 0; i < count; i++ {
            f(i)
        }
        cond.mutex.lock {
            done = true
            cond.broadcast()
        }
        wg.wait()
        XCTAssert(xtotal == total, "The expected total is incorrect. xtotal: \(xtotal), total: \(total)")
    }
    
    func testCondBroadcastZero() {
        for var i = 0; i < 50; i++ {
            _testCondBroadcast(0)
        }
    }
    func testCondBroadcastTen() {
        for var i = 0; i < 50; i++ {
            _testCondBroadcast(10)
        }
    }
    func testCondBroadcastHundred() {
        for var i = 0; i < 50; i++ {
            _testCondBroadcast(100)
        }
    }

    
    
    
}