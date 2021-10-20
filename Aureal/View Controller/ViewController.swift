import Cocoa
import Combine


class ViewModel {
    private let deviceManager = DeviceManager.shared

    @Published var devices = [AuraUSBDevice]()
    @Published var selectedDevice: AuraUSBDevice?

    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        selectedDevice = devices.first

        deviceManager.$devices
            .assign(to: \.devices, on: self)
            .store(in: &cancellableSet)
    }
}

class ViewController: NSViewController {
    @IBOutlet private var devicesPopUpButton: NSPopUpButton!
    @IBOutlet private var deviceContainer: NSView!

    private var cancellableSet: Set<AnyCancellable> = []

    lazy var viewModel: ViewModel = {
        ViewModel()
    }()

    private var deviceViewController: DeviceViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set up UI
        viewModel.$devices
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] devices in
                guard let self = self else {
                    return
                }

                self.devicesPopUpButton.removeAllItems()
                for device in devices {
                    self.devicesPopUpButton.addItem(withTitle: device.name)
                }

                if self.viewModel.selectedDevice == nil {
                    self.viewModel.selectedDevice = devices.first
                }
            })
            .store(in: &cancellableSet)

        viewModel.$selectedDevice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                guard let self = self else {
                    return
                }

                guard let device = device else {
                    self.hideDevice()

                    return
                }

                self.show(device: device)
            }
            .store(in: &cancellableSet)
    }

    @IBAction func handleDevice(sender: Any) {
        let idx = devicesPopUpButton.indexOfSelectedItem
        let device = viewModel.devices[idx]

        viewModel.selectedDevice = device
    }

    private func hideDevice() {
        deviceViewController?.view.removeFromSuperview()
        deviceViewController = nil
    }

    private func show(device: AuraUSBDevice) {
        if deviceViewController != nil {
            hideDevice()
        }

        guard
            let storyboard = storyboard,
            let vc = storyboard.instantiateController(withIdentifier: "DeviceViewController") as? DeviceViewController
        else {
            return
        }

        vc.viewModel = .init(device: device)
        vc.selectedDevice = viewModel.selectedDevice

        deviceContainer.addSubview(vc.view)
        vc.view.pinEdges()

        deviceViewController = vc
        vc.handleEffect(sender: self)
    }
}
