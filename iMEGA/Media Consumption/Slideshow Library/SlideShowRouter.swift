import UIKit
import MEGADomain
import MEGAData

struct SlideShowRouter: Routing {
    private weak var presenter: UIViewController?
    private let dataProvider: PhotoBrowserDataProvider
    
    init(dataProvider: PhotoBrowserDataProvider, presenter: UIViewController?) {
        self.dataProvider = dataProvider
        self.presenter = presenter
    }
    
    private func configSlideShowViewModel() async -> SlideShowViewModel {
        let photoEntities = await dataProvider.fetchOnlyPhotoEntities(mediaUseCase: MediaUseCase())
        
        var preferenceRepo: PreferenceRepository
        if let slideshowUserDefaults = UserDefaults(suiteName: "slideshow") {
            preferenceRepo = PreferenceRepository(userDefaults: slideshowUserDefaults)
        } else {
            preferenceRepo = PreferenceRepository.newRepo
        }
        
        return SlideShowViewModel(dataSource: slideShowDataSource(photos: photoEntities),
                                  slideShowUseCase: SlideShowUseCase(preferenceRepo: preferenceRepo),
                                  userUseCase: UserUseCase(repo: .live))
    }
    
    private func slideShowDataSource(photos: [NodeEntity]) -> SlideShowDataSource {
        SlideShowDataSource(
            currentPhoto: dataProvider.currentPhoto?.toNodeEntity(),
            nodeEntities: photos,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            fileDownloadUseCase: FileDownloadUseCase(fileCacheRepository: FileCacheRepository.newRepo,
                                                     fileSystemRepository: FileSystemRepository.newRepo,
                                                     downloadFileRepository: DownloadFileRepository.newRepo),
            mediaUseCase: MediaUseCase(),
            fileExistenceUseCase: FileExistUseCase(fileSystemRepository: FileSystemRepository.newRepo),
            advanceNumberOfPhotosToLoad: 20,
            numberOfUnusedPhotosBuffer: 20
        )
    }
    
    func build() -> UIViewController {
        let storyboard: UIStoryboard = UIStoryboard(name: "Slideshow", bundle: nil)
        let slideShowVC = storyboard.instantiateInitialViewController() as! SlideShowViewController
        Task {
            let vm = await configSlideShowViewModel()
            await slideShowVC.update(viewModel: vm)
        }
        return slideShowVC
    }
    
    func start() {
        guard let slideshowVC = build() as? SlideShowViewController else { return }
        presenter?.present(slideshowVC, animated: true)
    }
}
