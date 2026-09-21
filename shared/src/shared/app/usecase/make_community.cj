package tsn.shared.app.usecase

public struct MakeCommunity {
    public func perform(peerId: VArray<Byte, $16>): Unit {
        println("cj: peerId first byte is ${peerId[0]}")
    }
}
