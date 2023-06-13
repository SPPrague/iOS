import MEGADomain
import MEGAPresentation

enum TextEditorViewAction: ActionType {
    case setUpView
    case saveText(content: String)
    case renameFile
    case renameFileTo(newInputName: String)
    case uploadFile
    case dismissTextEditorVC
    case editFile
    case showActions(sender: Any)
    case cancelText(content: String)
    case cancel
    case downloadToOffline
    case importNode
    case exportFile(sender: Any)
    case editAfterOpen
}

@objc enum TextEditorMode: Int, CaseIterable {
    case create
    case edit
    case view
    case load
}

protocol TextEditorViewRouting: Routing {
    func chooseParentNode(completion: @escaping (HandleEntity) -> Void)
    func dismissTextEditorVC()
    func dismissBrowserVC()
    func showActions(nodeHandle: HandleEntity, delegate: NodeActionViewControllerDelegate, sender button: Any)
    func showPreviewDocVC(fromFilePath path: String, showUneditableError: Bool)
    func importNode(nodeHandle: HandleEntity?)
    func exportFile(from node: NodeEntity, sender button: Any)
    func showDownloadTransfer(node: NodeEntity)
    func sendToChat(node: MEGANode)
    func restoreTextFile(node: MEGANode)
    func viewInfo(node: MEGANode)
    func viewVersions(node: MEGANode)
    func removeTextFile(node: MEGANode)
    func shareLink(from nodeHandle: HandleEntity)
    func removeLink(from nodeHandle: HandleEntity)
}

final class TextEditorViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(_ textEditorModel: TextEditorModel, shallUpdateContent: Bool, isInRubbishBin: Bool, isBackupNode: Bool)
        case setupNavbarItems(_ navbarItemsModel: TextEditorNavbarItemsModel)
        case setupLoadViews
        case showDuplicateNameAlert(_ textEditorDuplicateNameAlertModel: TextEditorDuplicateNameAlertModel)
        case showRenameAlert(_ textEditorRenameAlertModel: TextEditorRenameAlertModel)
        case stopLoading
        case startLoading
        case editFile
        case updateProgressView(progress: Float)
        case showError(message: String)
        case showDiscardChangeAlert
    }
    
    var invokeCommand: ((Command) -> Void)?
    private var router: TextEditorViewRouting
    private var textFile: TextFile
    private var textEditorMode: TextEditorMode
    private var parentHandle: HandleEntity?
    private var nodeEntity: NodeEntity?
    private var uploadFileUseCase: any UploadFileUseCaseProtocol
    private var downloadNodeUseCase: any DownloadNodeUseCaseProtocol
    private var nodeUseCase: any NodeUseCaseProtocol
    private var backupsUseCase: any BackupsUseCaseProtocol
    private var shouldEditAfterOpen: Bool = false
    private var showErrorWhenToSetupView: Command?
    private var isBackupNode: Bool = false
    
    init(
        router: TextEditorViewRouting,
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        uploadFileUseCase: any UploadFileUseCaseProtocol,
        downloadNodeUseCase: any DownloadNodeUseCaseProtocol,
        nodeUseCase: any NodeUseCaseProtocol,
        backupsUseCase: any BackupsUseCaseProtocol,
        parentHandle: HandleEntity? = nil,
        nodeEntity: NodeEntity? = nil
    ) {
        self.router = router
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.uploadFileUseCase = uploadFileUseCase
        self.downloadNodeUseCase = downloadNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.backupsUseCase = backupsUseCase
        self.parentHandle = parentHandle
        self.nodeEntity = nodeEntity
    }
    
    func dispatch(_ action: TextEditorViewAction) {
        switch action {
        case .setUpView:
            if let nodeEntity {
                isBackupNode = backupsUseCase.isBackupNode(nodeEntity)
            }
            setupView(shallUpdateContent: true)
        case .saveText(let content):
            saveText(content: content)
        case .renameFile:
            invokeCommand?(.showRenameAlert(makeTextEditorRenameAlertModel()))
        case .renameFileTo(let newInputName):
            renameFileTo(newInputName: newInputName)
        case .uploadFile:
            uploadFile()
        case .dismissTextEditorVC:
            router.dismissTextEditorVC()
        case .editFile:
            editFile(shallUpdateContent: false)
        case .editAfterOpen:
            editAfterOpen()
        case .showActions(sender: let button):
            guard let handle = nodeEntity?.handle else { return }
            router.showActions(nodeHandle: handle, delegate: self, sender: button)
        case .cancelText(let content):
            cancelText(content: content)
        case .cancel:
            cancel()
        case .downloadToOffline:
            downloadToOffline()
        case .importNode:
            router.importNode(nodeHandle: nodeEntity?.handle)
        case .exportFile(sender: let button):
            exportFile(sender: button)
        }
    }
    
    // MARK: - Private functions
    private func setupView(shallUpdateContent: Bool) {
        var isNodeInRubbishBin = false
        if let nodeHandle = nodeEntity?.handle {
            isNodeInRubbishBin = nodeUseCase.isInRubbishBin(nodeHandle: nodeHandle)
        }
        
        if textEditorMode == .load {
            invokeCommand?(.setupLoadViews)
            invokeCommand?(.configView(makeTextEditorModel(), shallUpdateContent: false, isInRubbishBin: isNodeInRubbishBin, isBackupNode: isBackupNode))
            invokeCommand?(.setupNavbarItems(makeNavbarItemsModel()))
            downloadToTempFolder()
        } else {
            invokeCommand?(.configView(makeTextEditorModel(), shallUpdateContent: shallUpdateContent, isInRubbishBin: isNodeInRubbishBin, isBackupNode: isBackupNode))
            invokeCommand?(.setupNavbarItems(makeNavbarItemsModel()))
        }
        
        if let command = showErrorWhenToSetupView {
            invokeCommand?(command)
            showErrorWhenToSetupView = nil
        }
    }
    
    private func saveText(content: String) {
        textFile.content = content
        if textEditorMode == .edit {
            invokeCommand?(.startLoading)
            uploadFile()
        } else if textEditorMode == .create {
            if let parentHandle = parentHandle {
                uploadTo(parentHandle)
            } else {
                router.chooseParentNode { (parentHandle) in
                    self.uploadTo(parentHandle)
                }
            }
        }
    }
    
    private func makeTextEditorRenameAlertModel() -> TextEditorRenameAlertModel {
        TextEditorRenameAlertModel(
            alertTitle: Strings.Localizable.rename,
            alertMessage: Strings.Localizable.renameNodeMessage,
            cancelButtonTitle: Strings.Localizable.cancel,
            renameButtonTitle: Strings.Localizable.rename,
            textFileName: textFile.fileName
        )
    }
    
    private func renameFileTo(newInputName: String) {
        textFile.fileName = newInputName
        guard let parentHandle = parentHandle else { return }
        uploadTo(parentHandle)
    }
    
    private func uploadFile() {
        guard let parentHandle = parentHandle else { return }
        let fileName = textFile.fileName
        let content = textFile.content
        let tempUrl = uploadFileUseCase.tempURL(forFilename: fileName)
        do {
            try content.write(toFile: tempUrl.path, atomically: true, encoding: String.Encoding(rawValue: textFile.encode))
            uploadFileUseCase.uploadFile(tempUrl, toParent: parentHandle, fileName: nil, appData: nil, isSourceTemporary: false, startFirst: false, start: nil, update: nil) { result in
                if self.textEditorMode == .edit {
                    self.invokeCommand?(.stopLoading)
                }
                
                switch result {
                case .failure:
                    self.invokeCommand?(.showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload))
                case .success:
                    if self.textEditorMode == .edit {
                        self.textEditorMode = .view
                        self.setupView(shallUpdateContent: false)
                    }
                }
            }
            if self.textEditorMode == .create {
                router.dismissTextEditorVC()
            }
        } catch {
            MEGALogDebug("Could not write to file \(tempUrl) with error \(error.localizedDescription)")
        }
    }
    
    private func editFile(shallUpdateContent: Bool) {
        if textFile.size < TextFile.maxEditableFileSize {
            textEditorMode = .edit
            setupView(shallUpdateContent: shallUpdateContent)
        } else {
            if invokeCommand != nil {
                invokeCommand?(.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile))
            } else {
                showErrorWhenToSetupView = .showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)
            }
        }
    }
    
    private func editAfterOpen() {
        if textEditorMode == .view {
            editFile(shallUpdateContent: true)
        } else if textEditorMode == .load {
            shouldEditAfterOpen = true
        }
    }
    
    private func cancelText(content: String) {
        if content != textFile.content {
            invokeCommand?(.showDiscardChangeAlert)
        } else {
            cancel()
        }
    }
    
    private func cancel() {
        if textEditorMode == .create {
            router.dismissTextEditorVC()
        } else if textEditorMode == .edit {
            textEditorMode = .view
            self.setupView(shallUpdateContent: true)
        }
    }
    
    private func downloadToOffline() {
        guard let nodeEntity = nodeEntity else {
            return
        }
        
        router.showDownloadTransfer(node: nodeEntity)
    }
    
    private func downloadToTempFolder() {
        guard let nodeHandle = nodeEntity?.handle else { return }
        downloadNodeUseCase.downloadFileToTempFolder(nodeHandle: nodeHandle, appData: nil) { (transferEntity) in
            let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)
            self.invokeCommand?(.updateProgressView(progress: percentage))
        } completion: { (result) in
            switch result {
            case .failure:
                self.invokeCommand?(.showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.download))
            case .success(let transferEntity):
                guard let path = transferEntity.path else { return }
                do {
                    var encode: String.Encoding = .utf8
                    self.textFile.content = try String(contentsOfFile: path, usedEncoding: &encode)
                    self.textFile.encode = encode.rawValue
                    if self.shouldEditAfterOpen {
                        self.editFile(shallUpdateContent: true)
                        self.shouldEditAfterOpen = false
                    } else {
                        self.textEditorMode = .view
                        self.setupView(shallUpdateContent: true)
                    }
                } catch {
                    self.router.showPreviewDocVC(fromFilePath: path, showUneditableError: self.shouldEditAfterOpen)
                }
            }
        }
    }
    
    private func makeTextEditorModel() -> TextEditorModel {
        switch textEditorMode {
        case .view:
            return TextEditorModel(
                textFile: textFile,
                textEditorMode: textEditorMode,
                accessLevel: nodeAccessLevel()
            )
        case .load,
             .edit,
             .create:
            return TextEditorModel(
                textFile: textFile,
                textEditorMode: textEditorMode,
                accessLevel: nil
            )
        }
    }
    
    private func makeNavbarItemsModel() -> TextEditorNavbarItemsModel {
        switch textEditorMode {
        case .load:
            return TextEditorNavbarItemsModel(
                leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
                rightItem: nil,
                textEditorMode: textEditorMode
            )
        case .view:
            return TextEditorNavbarItemsModel(
                leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
                rightItem: NavbarItemModel(title: nil, imageName: Asset.Images.NavigationBar.moreNavigationBar.name),
                textEditorMode: textEditorMode
            )
        case .edit,
             .create:
            return TextEditorNavbarItemsModel(
                leftItem: NavbarItemModel(title: Strings.Localizable.cancel, imageName: nil),
                rightItem: NavbarItemModel(title: Strings.Localizable.save, imageName: nil),
                textEditorMode: textEditorMode
            )
        }
    }
    
    private func nodeAccessLevel() -> NodeAccessTypeEntity {
        isBackupNode ? .read : nodeUseCase.nodeAccessLevel(nodeHandle: nodeEntity?.handle ?? .invalid)
    }
    
    private func uploadTo(_ parentHandle: HandleEntity) {
        self.parentHandle = parentHandle
        let isFileNameDuplicated = uploadFileUseCase.hasExistFile(name: textFile.fileName, parentHandle: parentHandle)
        if isFileNameDuplicated {
            invokeCommand?(.showDuplicateNameAlert(
                TextEditorDuplicateNameAlertModel(
                    alertTitle: Strings.Localizable.renameFileAlertTitle(textFile.fileName),
                    alertMessage: Strings.Localizable.thereIsAlreadyAFileWithTheSameName,
                    cancelButtonTitle: Strings.Localizable.cancel,
                    replaceButtonTitle: Strings.Localizable.replace,
                    renameButtonTitle: Strings.Localizable.rename)
            ))
        } else {
            uploadFile()
            router.dismissBrowserVC()
        }
    }
    
    private func exportFile(sender: Any) {
        guard let nodeEntity = nodeEntity else {
            return
        }
        
        router.exportFile(from: nodeEntity, sender: sender)
    }
}

extension TextEditorViewModel: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .editTextFile:
            editFile(shallUpdateContent: false)
        case .download:
            router.showDownloadTransfer(node: node.toNodeEntity())
        case .import:
            router.importNode(nodeHandle: node.handle)
        case .sendToChat:
            router.sendToChat(node: node)
        case .exportFile:
            exportFile(sender: sender)
        case .restore:
            router.restoreTextFile(node: node)
        case .info:
            router.viewInfo(node: node)
        case .viewVersions:
            router.viewVersions(node: node)
        case .remove:
            router.removeTextFile(node: node)
        case .shareLink, .manageLink:
            router.shareLink(from: node.handle)
        case .removeLink:
            router.removeLink(from: node.handle)
        default:
            break
        }
    }
}
