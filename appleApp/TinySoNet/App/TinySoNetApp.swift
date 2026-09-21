import SwiftUI

import TinySoNetKit

@main struct TinySoNetApp: App {
    init() { TSNMakeCommunityUsecase()?.perform(UUID()) }
    
    var body: some Scene {
        WindowGroup {
        }
    }
}
