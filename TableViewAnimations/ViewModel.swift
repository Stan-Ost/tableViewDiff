//
//  ViewModel.swift
//  TableViewAnimations
//
//  Created by Stanislav Ostrovskiy on 3/3/18.
//  Copyright © 2018 Stanislav Ostrovskiy. All rights reserved.
//

import Foundation
import UIKit

struct DataModelSection {
    var id: String
    var cells: [DataSourceModelItem]
}

struct DataSourceModelItem {
    var id: String
    var value: String
}

protocol ViewModelDelegate: class {
    func applyChanges(_ changes: SectionChanges)
    func reload()
}

class ViewModel: NSObject {
    
    var items = [DataModelSection]()
    
    weak var delegate: ViewModelDelegate?
    
    override init() {
        super.init()
        
        loadNewData(animated: false)
    }

    func loadNewData(animated: Bool = true) {
        let sectionKeyID = arc4random_uniform(5)
        
        var sections = [DataModelSection]()
        
        for sectionID in 0...sectionKeyID {
            let sectionKey = "Section \(sectionID)"
            
            var cells = [DataSourceModelItem]()
            
            let cellKeyID = arc4random_uniform(10)
            
            for cellID in 0...cellKeyID {
                let cellValueID = arc4random_uniform(20)
                let cellKey = "key\(cellID)"
                let cellValue = "value \(cellValueID)"
                let cellItem = DataSourceModelItem(id: cellKey, value: cellValue)
                cells.append(cellItem)
            }
            
            let sectionItem = DataModelSection(id: sectionKey, cells: cells)
            sections.append(sectionItem)
        }
        
        setData(sections, animated: animated)
    }
    
    private func setData(_ newItems: [DataModelSection], animated: Bool = true) {
        let oldData = flatten(data: items)
        let newData = flatten(data: newItems)
        
        if !animated {
            items = newItems
            delegate?.reload()
            return
        }
        
        // get diff for animated reload
        let diff = DiffCalculator.calculate(oldItems: oldData, newItems: newData)
        items = newItems
        delegate?.applyChanges(diff)
    }
    
    private func flatten(data: [DataModelSection]) -> [ReloadableSection<String>] {
        return data.enumerated().map { ReloadableSection(key: $0.element.id, value: $0.element.cells.enumerated().map { ReloadableCell(key: $0.element.id, value: $0.element.value, index: $0.offset) }, index: $0.offset) }
    }
}

extension ViewModel: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.section].cells[indexPath.row].value
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].id
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.backgroundView?.backgroundColor = UIColor.lightGray
    }
}
