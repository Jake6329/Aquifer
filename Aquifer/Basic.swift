//
//  Basic.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/28/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// part of `Pipes.Prelude`

import Foundation
import Swiftz

public func once<UO, UI, DI, DO, FR>(v: () -> FR) -> Proxy<UO, UI, DI, DO, FR> {
    return Proxy(ProxyRepr.Pure(v))
}

public func repeat<UO, UI, DO, FR>(v: () -> DO) -> Proxy<UO, UI, (), DO, FR> {
    return once(v) >~ cat()
}

public func replicate<UO, UI, DO>(v: () -> DO, n: Int) -> Proxy<UO, UI, (), DO, ()> {
    return once(v) >~ take(n)
}

public func take<DT>(n: Int) -> Proxy<(), DT, (), DT, ()> {
    if n <= 0 {
        return pure(())
    } else {
        return await() >>- { yield($0) >>- { _ in take(n - 1) } }
    }
}

public func takeWhile<DT>(predicate: DT -> Bool) -> Proxy<(), DT, (), DT, ()> {
    return await() >>- { v in
        if predicate(v) {
            return yield(v) >>- { _ in takeWhile(predicate) }
        } else {
            return pure(())
        }
    }
}

private func dropInner<DT>(n: Int) -> Proxy<(), DT, (), DT, ()> {
    if n <= 0 {
        return pure(())
    } else {
        return await() >>- { _ in dropInner(n - 1) }
    }
}

public func drop<DT, FR>(n: Int) -> Proxy<(), DT, (), DT, FR> {
    return dropInner(n) >>- { _ in cat() }
}

public func dropWhile<DT, FR>(predicate: DT -> Bool) -> Proxy<(), DT, (), DT, FR> {
    return await() >>- { v in
        if predicate(v) {
            return dropWhile(predicate)
        } else {
            return yield(v) >>- { _ in cat() }
        }
    }
}

public func concat<S: SequenceType, FR>() -> Proxy<(), S, (), S.Generator.Element, FR> {
    return for_(cat(), each)
}

public func drain<UI, DI, DO, FR>() -> Proxy<(), UI, DI, DO, FR> {
    return for_(cat(), discard)
}

public func map<UI, DO, FR>(f: UI -> DO) -> Proxy<(), UI, (), DO, FR> {
    return for_(cat()) { v in yield(f(v)) }
}

public func mapMany<UI, S: SequenceType, FR>(f: UI -> S) -> Proxy<(), UI, (), S.Generator.Element, FR> {
    return for_(cat()) { each(f($0)) }
}

public func filter<DT, FR>(predicate: DT -> Bool) -> Proxy<(), DT, (), DT, FR> {
    return for_(cat()) { v in
        if predicate(v) {
            return yield(v)
        } else {
            return pure(())
        }
    }
}