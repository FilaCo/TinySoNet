package tsn.shared.domain

import std.time.DateTime
import tsn.shared.domain.utils.Version

public struct Community {
    public Community(private let id: CommunityId, private let events: Array<CommunityEvent>) {}
}

public struct CommunityId {} 

public struct CommunityName {}

public struct CommunityOwnerId {}

public enum CommunityEvent {
    | Created(CommunityName, CommunityOwnerId, /* created at */DateTime, /* updated at */DateTime)
}

public struct Account {
    public Account(private let id: AccountId) {}
}

public struct AccountId {}

public struct AccountName {}

public struct Device {
    public Device(private let id: DeviceId, private let version: Version) {}
}

public struct DeviceId {}