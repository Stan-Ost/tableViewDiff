//
//  ViewController.swift
//  TableViewAnimations
//
//  Created by Stanislav Ostrovskiy on 3/3/18.
//  Copyright © 2018 Stanislav Ostrovskiy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel = ViewModel()
    
    private var isAnimated = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = viewModel
        
        viewModel.delegate = self
        
        tableView.reloadData()
    }
    
    private var animationStyle = UITableViewRowAnimation.fade
    
    @IBAction func reloadTableView(_ sender: Any) {
        viewModel.loadNewData(animated: isAnimated)
    }
    
    @IBAction func didSwitch(_ sender: UISwitch) {
        isAnimated = sender.isOn
    }
    
    @IBAction func didChangeAnimationStyle(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            animationStyle = .fade
        case 1:
            animationStyle = .none
        case 2:
            animationStyle = .automatic
        default:
            break
        }
    }
}

extension ViewController: ViewModelDelegate {
    func applyChanges(_ changes: SectionChanges) {
        tableView.beginUpdates()
        
        tableView.deleteSections(changes.deletes, with: animationStyle)
        tableView.insertSections(changes.inserts, with: animationStyle)
        
        tableView.reloadRows(at: changes.updates.reloads, with: animationStyle)
        tableView.insertRows(at: changes.updates.inserts, with: animationStyle)
        tableView.deleteRows(at: changes.updates.deletes, with: animationStyle)
        
        for cellMove in changes.updates.moves {
            tableView.moveRow(at: cellMove.from, to: cellMove.to)
        }
        
        for sectionMove in changes.movesInts {
            tableView.moveSection(sectionMove.from, toSection: sectionMove.to)
        }

        tableView.endUpdates()
    }
    
    func reload() {
        tableView.reloadData()
    }
}


