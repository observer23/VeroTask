//
//  HomeViewController.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import UIKit

class HomeViewController: BaseViewController{
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    private let refreshControl = UIRefreshControl()
    
    private var tasks: [TaskModel] = []{
        didSet{
            tableView.backgroundView = nil
        }
    }
    var searchedResults: [TaskModel] = []
    var isSearching = false {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTasks()
        updateBackgroundView()
    }
    
    @IBAction func qrScannerTapped(_ sender: UIBarButtonItem) {
        showQRScanner()
    }
    
    func updateSearchBar(with scannedValue: String) {
        searchBar.text = scannedValue
        searchBar.delegate?.searchBar?(searchBar, textDidChange: scannedValue)
        searchBar.becomeFirstResponder()
    }
    // MARK: - UI Setup
    private func setupUI() {
        setupTableView()
        setupSearchBar()
        setupRefreshControl()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
    }
    
    private func setupRefreshControl() {
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTasks), for: .valueChanged)
    }
    
    private func updateBackgroundView() {
        if tasks.isEmpty {
            let noDataLabel = UILabel()
            noDataLabel.text = "No tasks available"
            noDataLabel.textAlignment = .center
            noDataLabel.textColor = .gray
            tableView.backgroundView = noDataLabel
        } else {
            tableView.backgroundView = nil
        }
    }
    
    // MARK: - Task Loading
    private func loadTasks() {
        TaskManager.shared.fetchTasksFromCoreData { [weak self] tasks in
            DispatchQueue.main.async {
                self?.tasks = tasks
                self?.searchedResults = tasks
                self?.updateBackgroundView()
                self?.tableView.reloadData()
                self?.navigationItem.title = "Total tasks: \(tasks.count)"
            }
        }
    }
    
    @objc private func refreshTasks() {
        TaskManager.shared.syncTasksFromAPI { [weak self] tasks, error in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                if let tasks = tasks {
                    self?.tasks = tasks
                    self?.searchedResults = tasks
                    self?.updateBackgroundView()
                    self?.navigationItem.title = "Total tasks: \(tasks.count)"
                    self?.tableView.reloadData()
                    if let err =  error{
                        self?.showErrorAlert(message: err)
                    }
                } else {
                    self?.showErrorAlert(message: "Failed to refresh tasks.")
                }
            }
        }
    }
    
    private func showDetail(task: TaskModel) {
        let alert = UIAlertController(title: task.title, message: task.taskDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - TableView Delegate & DataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchedResults.count : tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCellTableViewCell
        let task = isSearching ? searchedResults[indexPath.row] : tasks[indexPath.row]
        cell.configure(with: task)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = isSearching ? searchedResults[indexPath.row] : tasks[indexPath.row]
        self.showDetail(task: task)
    }
}

// MARK: - SearchBar Delegate
extension HomeViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            // Clear search state
            isSearching = false
            searchedResults = tasks
            self.navigationItem.title = "Total tasks: \(searchedResults.count)"
            
        } else {
            // Apply search filter
            isSearching = true
            searchedResults = tasks.filter { task in
                let title = task.title?.lowercased() ?? ""
                let description = task.taskDescription?.lowercased() ?? ""
                return title.contains(searchText.lowercased()) || description.contains(searchText.lowercased())
            }
            self.navigationItem.title = "Total tasks: \(searchedResults.count)"
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Reset search bar and state
        isSearching = false
        searchBar.text = ""
        searchedResults = tasks
        tableView.reloadData()
    }
}

extension HomeViewController:QRCodeScannerDelegate{
    func showQRScanner() {
        let qrScannerVC = QRCodeScannerViewController()
        qrScannerVC.delegate = self
        qrScannerVC.modalPresentationStyle = .popover
        present(qrScannerVC, animated: true)
    }
    // MARK: - QRCodeScannerDelegate Methods
    func qrCodeScanner(_ scanner: QRCodeScannerViewController, didScanCode code: String) {
        dismiss(animated: true) {
            let alert = UIAlertController(title: "QR Code Scanned", message: code, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Search", style: .default) { _ in
                self.updateSearchBar(with: code)
            })
            self.present(alert, animated: true)
        }
    }
    
    func qrCodeScannerDidFailWithError(_ scanner: QRCodeScannerViewController, error: Error?) {
        dismiss(animated: true) {
            let alert = UIAlertController(title: "Scanning Error", message: error?.localizedDescription ?? "Unknown error", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func qrCodeScannerDidCancel(_ scanner: QRCodeScannerViewController) {
        dismiss(animated: true)
    }
    
}
