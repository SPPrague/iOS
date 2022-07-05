@testable import MEGA

final class MockNodeActionUseCase: NodeActionUseCaseProtocol {
    var nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown
    var labelString: String = ""
    
    var filesAndFolders = (0, 0)
    var versions: Bool = false
    var downloaded: Bool = false
    var inRubbishBin: Bool = false
    let slideShowImages: [NodeEntity]
    
    init(slideShowImages: [NodeEntity] = []) {
        self.slideShowImages = slideShowImages
    }
    
    func nodeAccessLevel() -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    func downloadToOffline() { }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFolders
    }
    
    func hasVersions() -> Bool {
        versions
    }
    
    func isDownloaded() -> Bool {
        downloaded
    }
    
    func isInRubbishBin() -> Bool {
        inRubbishBin
    }
    
    func slideShowImages(for node: NodeEntity) -> [NodeEntity] {
        slideShowImages
    }
}
