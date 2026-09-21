package tsn.objc.usecase

import objc.lang.*
import tsn.objc.foundation.{NSObject, NSUUID}
import tsn.shared.app.usecase.MakeCommunity as MakeCommunityImpl

@ObjCImpl["TSNMakeCommunityUsecase"]
class MakeCommunity <: NSObject {
    private let impl: MakeCommunityImpl

    public MakeCommunity() {
        impl = MakeCommunityImpl()
    }

    public func perform(peerId: NSUUID): Unit {
        var peerIdBytes = VArray<Byte, $16>(repeat: 0)
        peerId.getUUIDBytes(ObjCPointer(CPointer<Unit>(inout peerIdBytes)))
        impl.perform(peerIdBytes)
    }
}
