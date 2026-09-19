package tsn.objc.usecase

import objc.lang.*
import tsn.objc.foundation.NSObject
import tsn.shared.app.usecase.MakeCommunity as MakeCommunityImpl

@ObjCImpl["TSNMakeCommunityUsecase"]
class MakeCommunity <: NSObject {
    private let impl: MakeCommunityImpl

    public MakeCommunity() {
        impl = MakeCommunityImpl()
    }

    public func perform(): Unit {
        impl.perform()
    }
}
