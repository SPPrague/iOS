import SwiftUI
import Combine
import MEGADomain

protocol AlbumListViewRouting {
    func cell(album: AlbumEntity) -> AlbumCell
    func albumContent(album: AlbumEntity) -> AlbumContainerWrapper
}

struct AlbumListViewRouter: AlbumListViewRouting, Routing {
    
    func cell(album: AlbumEntity) -> AlbumCell {
        let vm = AlbumCellViewModel(
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            album: album
        )
        return AlbumCell(viewModel: vm)
    }
    
    func albumContent(album: AlbumEntity) -> AlbumContainerWrapper {
        return AlbumContainerWrapper(album: album)
    }
    
    func build() -> UIViewController {
        let vm = AlbumListViewModel(
            usecase: AlbumListUseCase(
                albumRepository: AlbumRepository.newRepo,
                fileSearchRepository: FileSearchRepository.newRepo,
                mediaUseCase: MediaUseCase()
            )
        )
        let content = AlbumListView(viewModel: vm, router: self)
        
        return UIHostingController(rootView: content)
    }
    
    func start() {}
}
