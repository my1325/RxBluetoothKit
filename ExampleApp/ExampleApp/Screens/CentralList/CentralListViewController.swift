import RxBluetoothKit
import RxSwift
import UIKit

class CentralListViewController: UITableViewController {

    init(bluetoothProvider: BluetoothProvider) {
        self.bluetoothProvider = bluetoothProvider
        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(startSearch)
        )
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(CentralListCell.self, forCellReuseIdentifier: CentralListCell.reuseId)
    }

    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        scannedPeripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CentralListCell.reuseId, for: indexPath) as? CentralListCell else {
            fatalError("Something went wrong :(")
        }

        let peripheral = scannedPeripherals[indexPath.row]
        cell.identifierLabel.text = peripheral.peripheral.identifier.uuidString
        cell.nameLabel.text = "name: " + (peripheral.peripheral.peripheral.name ?? "jjj")
        cell.rssiLabel.text = "rssi: \(peripheral.rssi.intValue)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = scannedPeripherals[indexPath.row]

        bluetoothProvider.connect(to: peripheral.peripheral)
            .subscribe(
                onNext: { [weak self] in self?.pushServicesController(with: $0) },
                onError: { [weak self] in AlertPresenter.presentError(with: $0.printable, on: self?.navigationController) }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Private

    private var scannedPeripherals: [ScannedPeripheral] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private let bluetoothProvider: BluetoothProvider
    private var disposeBag = DisposeBag()

    @objc private func startSearch() {
        disposeBag = DisposeBag()
        bluetoothProvider.startScanning()
            .subscribe(onNext: { [weak self] newValue in
                if let index = self?.scannedPeripherals.firstIndex(where: { $0.peripheral.identifier == newValue.peripheral.identifier }) {
                    self?.scannedPeripherals.remove(at: index)
                    self?.scannedPeripherals.insert(newValue, at: index)
                } else {
                    self?.scannedPeripherals.append(newValue)
                }
            })
            .disposed(by: disposeBag)
    }

    private func pushServicesController(with peripheral: Peripheral) {
        let controller = CentralSericesViewController(peripheral: peripheral, bluetoothProvider: bluetoothProvider)
        navigationController?.pushViewController(controller, animated: true)
    }

}
