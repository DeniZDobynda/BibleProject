//
//  DownloadViewController.swift
//  SplitB
//
//  Created by Denis Dobanda on 24.10.18.
//  Copyright © 2018 Denis Dobanda. All rights reserved.
//

import UIKit
import CoreData

class DownloadViewController: UIViewController {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var containerView: UIView!
    
    private var modules: [ModuleOffline] = []
    private var modulesDownloaded: [String] = []
    private var modulesDownloading: [IndexPath]? = []
    private var context = AppDelegate.context
    private var downloadManager = DownloadManager(in: AppDelegate.context)
    private var manager: Manager = Manager(in: AppDelegate.context)
    
    private var sections = ["Bible", "Local Bible",
                            "Strong Numbers", "Spirit of Prophesy"]
    private var localModules: [Module] = []
    private var strongsNumbersNames: [String] = []
    private var localSpirit: [SpiritBook] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.isHidden = false
        containerView.isHidden = true
        table.delegate = self; table.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadInfo()
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            table.isHidden = false
            containerView.isHidden = true
        case 1:
            table.isHidden = true
            containerView.isHidden = false
        default:
            break
        }
    }
    
    private func loadInfo() {
        localModules = []
        strongsNumbersNames = []
        localSpirit = []
        modules = [
            ModuleOffline("King James Version", "kjv"),
            ModuleOffline("Schlachter 1951", "schlachter"),
            ModuleOffline("Luther (1545)", "luther1545"),
            ModuleOffline("Synodal Translation (1876)", "synodal")
        ]
        modulesDownloaded = manager.getAvailableModules()?.map() {$0.key?.lowercased() ?? ""} ?? []
        localModules = (try? Module.getAll(from: context, local: true)) ?? []
        localSpirit = (try? SpiritBook.getAll(from: context)) ?? []
        if let b = try? Strong.exists(StrongId.oldTestament, in: context), b {
            strongsNumbersNames.append(StrongId.oldTestament)
        }
        if let b = try? Strong.exists(StrongId.newTestament, in: context), b {
            strongsNumbersNames.append(StrongId.newTestament)
        }
        table.beginUpdates()
        table.endUpdates()
    }
}


extension DownloadViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return modules.count
        case 1:
            return localModules.count
        case 2:
            return strongsNumbersNames.count
        case 3:
            return localSpirit.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "Module Cell", for: indexPath)
        if let c = cell as? DownloadCell {
            switch indexPath.section {
            case 0:
                let m = modules[indexPath.row]
                c.accessoryType = modulesDownloaded.contains(m.key) ? .checkmark : .none
                c.left = m.key
                c.right = m.name
            case 1:
                c.accessoryType = .checkmark
                c.left = localModules[indexPath.row].key
                c.right = localModules[indexPath.row].name
            case 2:
                c.accessoryType = .checkmark
                c.left = nil
                c.right = strongsNumbersNames[indexPath.row]
            case 3:
                c.accessoryType = .checkmark
                c.left = localSpirit[indexPath.row].code
                c.right = localSpirit[indexPath.row].name
            default:break
            }
            c.columnWidth = view.bounds.width * 0.27
        }
        
        return cell
    }
    
}

extension DownloadViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? DownloadCell else { return }
        
        switch indexPath.section {
        case 0:
            deleteOrDownloadModule(at: indexPath, cell: cell)
        case 1:
            deleteLocalBible(at: indexPath.row)
        case 2:
            deleteStrong(at: indexPath.row)
        case 3:
            deleteSpirit(at: indexPath.row)
        default:break
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    private func deleteOrDownloadModule(at indexPath: IndexPath, cell: DownloadCell) {
        cell.setSelected(false, animated: true)
        if cell.accessoryType == .none {
            if cell.isLoading {
                print("terminating? not now, sorry")
            } else {
                // download
                cell.isLoading = true
                let module = modules[indexPath.row]
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.downloadManager.downloadAsync(module) { [weak self] (success, error) in
                        if success {
                            self?.modulesDownloaded.append(module.key)
                            DispatchQueue.main.async {
                                cell.accessoryType = .checkmark
                                cell.isLoading = false
                                self?.table.beginUpdates()
                                self?.table.endUpdates()
                            }
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                self?.present(alert, animated:true, completion:nil)
                                cell.isLoading = false
                            }
                        }
                    }
                }
            }
        } else {
            // delete
            let module = modules[indexPath.row]
            let alert = UIAlertController(title: "Alert", message: "Delete \(module.name) Module?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title:"Yes", style:.default, handler:{ [weak self] _ in
                self?.downloadManager.removeAsync(module) { [weak self] (success, error) in
                    if success {
                        self?.modulesDownloaded.removeAll(where: { (key) -> Bool in
                            return key == module.key
                        })
                        DispatchQueue.main.async {
                            cell.accessoryType = .none
                            self?.table.beginUpdates()
                            self?.table.endUpdates()
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self?.present(alert, animated:true, completion:nil)
                        }
                    }
                }
                
            }))
            self.present(alert, animated: true) {
                self.table.beginUpdates()
                self.table.endUpdates()
            }
        }
    }
    
    private func deleteLocalBible(at index: Int) {
        let s = localModules[index]
        DispatchQueue.global(qos: .userInteractive).async {
            self.context.delete(s)
            try? self.context.save()
        }
        
        localModules.remove(at: index)
        table.reloadData()
    }
    
    private func deleteStrong(at index: Int) {
        let s = strongsNumbersNames[index]
        DispatchQueue.global(qos: .userInteractive).async {
            if let numbers = try? Strong.get(by: s, from: self.context) {
                for number in numbers {
                    self.context.delete(number)
                }
            }
            try? self.context.save()
        }
        strongsNumbersNames.remove(at: index)
        table.reloadData()
    }
    
    private func deleteSpirit(at index: Int) {
        let s = localSpirit[index]
        DispatchQueue.global(qos: .userInteractive).async {
            self.context.delete(s)
            try? self.context.save()
        }
        
        localModules.remove(at: index)
        table.reloadData()
    }
}
