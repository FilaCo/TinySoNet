package tsn.shared.domain

struct CommunityCreated {
    CommunityCreated(let creatorId: PeerId, let communityId: CommunityId) {}
}

struct PeerId {}

struct CommunityId {}