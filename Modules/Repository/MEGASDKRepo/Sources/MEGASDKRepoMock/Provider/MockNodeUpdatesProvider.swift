import MEGADomain
import MEGASDKRepo
import MEGASwift

public struct MockNodeUpdatesProvider: NodeUpdatesProviderProtocol {
    public let nodeUpdates: AnyAsyncSequence<[NodeEntity]>
    
    public init(nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.nodeUpdates = nodeUpdates
    }
}
