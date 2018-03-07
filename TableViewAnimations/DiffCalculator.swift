import Foundation

class SectionChanges: Equatable {
    fileprivate var insertsInts = [Int]()
    fileprivate var deletesInts = [Int]()
    fileprivate (set) var movesInts = [(from: Int, to: Int)]()
    fileprivate (set) var updates = CellChanges()
    
    var inserts: IndexSet {
        return IndexSet(insertsInts)
    }
    var deletes: IndexSet {
        return IndexSet(deletesInts)
    }
    
    init(inserts: [Int] = [], deletes: [Int] = [], moves: [(from: Int, to: Int)] = [], updates: CellChanges = CellChanges()) {
        self.insertsInts = inserts
        self.deletesInts = deletes
        self.updates = updates
        self.movesInts = moves
    }
    
    static func ==(lhs: SectionChanges, rhs: SectionChanges) -> Bool {
        return lhs.insertsInts == rhs.insertsInts && lhs.deletesInts == rhs.deletesInts && lhs.updates == rhs.updates && lhs.movesInts.map {$0.from} == rhs.movesInts.map {$0.from} && lhs.movesInts.map {$0.to} == rhs.movesInts.map {$0.to}
    }
}

class CellChanges: Equatable {
    fileprivate (set) var inserts = [IndexPath]()
    fileprivate (set) var deletes = [IndexPath]()
    fileprivate (set) var reloads = [IndexPath]()
    fileprivate (set) var moves = [(from: IndexPath, to: IndexPath)]()
    
    init(inserts: [IndexPath] = [], deletes: [IndexPath] = [], reloads: [IndexPath] = [], moves: [(from: IndexPath, to: IndexPath)] = []) {
        self.inserts = inserts
        self.deletes = deletes
        self.reloads = reloads
        self.moves = moves
    }
    
    static func ==(lhs: CellChanges, rhs: CellChanges) -> Bool {
        return lhs.inserts == rhs.inserts && lhs.deletes == rhs.deletes && lhs.reloads == rhs.reloads && lhs.moves.map { $0.from } == rhs.moves.map { $0.from } && lhs.moves.map { $0.to } == rhs.moves.map { $0.to }
    }
}

struct ReloadableSection<N: Equatable>: Equatable, Comparable {
    private (set) var key: String
    var value: [ReloadableCell<N>]
    private (set) var index: Int
    
    static func ==(lhs: ReloadableSection, rhs: ReloadableSection) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
    
    static func >(lhs: ReloadableSection, rhs:ReloadableSection) -> Bool {
        return lhs.index > rhs.index
    }
    
    static func <(lhs: ReloadableSection, rhs:ReloadableSection) -> Bool {
        return lhs.index < rhs.index
    }
}

struct ReloadableCell<N:Equatable>: Equatable, Comparable {
    private (set) var key: String
    var value: N
    private (set) var index: Int
    
    static func ==(lhs: ReloadableCell, rhs: ReloadableCell) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
    
    static func >(lhs: ReloadableCell, rhs:ReloadableCell) -> Bool {
        return lhs.index > rhs.index
    }
    
    static func <(lhs: ReloadableCell, rhs:ReloadableCell) -> Bool {
        return lhs.index < rhs.index
    }
}

struct ReloadableSectionData<N: Equatable> {
    fileprivate var items = [ReloadableSection<N>]()
    
    fileprivate subscript(key: String) -> ReloadableSection<N>? {
        get {
            return items.filter { $0.key == key }.first
        }
    }
    
    fileprivate subscript(index: Int) -> ReloadableSection<N>? {
        get {
            return items.filter { $0.index == index }.first
        }
    }
}

struct ReloadableCellData<N: Equatable> {
    fileprivate var items = [ReloadableCell<N>]()
    
    fileprivate subscript(key: String) -> ReloadableCell<N>? {
        get {
            return items.filter { $0.key == key }.first
        }
    }
    
    fileprivate subscript(index: Int) -> ReloadableCell<N>? {
        get {
            return items.filter { $0.index == index }.first
        }
    }
}

class DiffCalculator {

    static func calculate<N>(oldItems: [ReloadableSection<N>], newItems: [ReloadableSection<N>]) -> SectionChanges {
        
        let time = Date()
        
        let sectionChanges = SectionChanges()
        let uniqueSectionKeys = (oldItems + newItems)
            .map { $0.key }
            .filterDuplicates()
        
        var cellChanges = CellChanges()
        let oldSectionData = ReloadableSectionData(items: oldItems)
        let newSectionData = ReloadableSectionData(items: newItems)
        
        for sectionKey in uniqueSectionKeys {
            let oldSectionItem = oldSectionData[sectionKey]
            let newSectionItem = newSectionData[sectionKey]
            if let oldSectionItem = oldSectionItem, let newSectionItem = newSectionItem {
                if oldSectionItem.index == newSectionItem.index {
                    let sectionIndex = oldSectionItem.index
                    if oldSectionItem == newSectionItem {
                        // indices and values are equal
                        // do nothing
                    } else {
                        // section updates with the same index
                        // go through each cell in the section
                        if !oldSectionItem.value.isEmpty && !newSectionItem.value.isEmpty {
                            getCellUpdates(sectionIndex: sectionIndex, oldSectionItem: oldSectionItem, newSectionItem: newSectionItem, cellChanges: &cellChanges)
                        } else if oldSectionItem.value.isEmpty {
                            sectionChanges.insertsInts.append(newSectionItem.index)
                        } else if newSectionItem.value.isEmpty {
                            sectionChanges.deletesInts.append(oldSectionItem.index)
                        }
                    }
                } else {
                    // index has changed
                    if newSectionItem == oldSectionItem {
                        // move section
                        sectionChanges.movesInts.append((from: oldSectionItem.index, to: newSectionItem.index))
                    } else {
                        // section moved and changed
                        sectionChanges.deletesInts.append(oldSectionItem.index)
                        sectionChanges.insertsInts.append(newSectionItem.index)
                    }
                }
            } else if let oldSectionItem = oldSectionItem {
                sectionChanges.deletesInts.append(oldSectionItem.index)
            } else if let newSectionItem = newSectionItem {
                sectionChanges.insertsInts.append(newSectionItem.index)
            }
        }

        // if the same cell index was deleted and inserted -> it should be just reloaded
        let cellsToReload = cellChanges.deletes.filter () { cellChanges.inserts.contains($0) }
        for index in cellsToReload {
            if let deletedIndex = cellChanges.deletes.index(of: index), let insertedIndex = cellChanges.inserts.index(of: index) {
                cellChanges.reloads.append(index)
                cellChanges.inserts.remove(at: insertedIndex)
                cellChanges.deletes.remove(at: deletedIndex)
            }
        }
        
        sectionChanges.updates = cellChanges
        
        let newTime = Date()
        let timeDiff = newTime.timeIntervalSince(time)
        print(timeDiff)
        
        return sectionChanges
    }
    
    private static func getCellUpdates<N>(sectionIndex: Int, oldSectionItem: ReloadableSection<N>, newSectionItem: ReloadableSection<N>, cellChanges: inout CellChanges) {
        let oldCellIData = ReloadableCellData(items: oldSectionItem.value.sorted())
        let newCellData = ReloadableCellData(items: newSectionItem.value.sorted())
        
        let uniqueCellKeys = (oldCellIData.items + newCellData.items)
            .map { $0.key }
            .filterDuplicates()
        
        for cellKey in uniqueCellKeys {
            let oldCellItem = oldCellIData[cellKey]
            let newCellItem = newCellData[cellKey]
            if let oldCellItem = oldCellItem, let newCellItem = newCellItem {
                
                if oldCellItem.index == newCellItem.index {
                    let cellIndex = oldCellItem.index
                    if newCellItem != oldCellItem {
                        cellChanges.reloads.append(IndexPath(row: cellIndex, section: sectionIndex))
                    } else {
                        // items are equal on the same indices
                        // Do nothing
                    }
                } else {
                    // index has changed
                    if newCellItem == oldCellItem {
                        // cell moved
                        cellChanges.moves.append((from: IndexPath(row: oldCellItem.index, section: sectionIndex), to: IndexPath(row: newCellItem.index, section: sectionIndex)))
                    } else {
                        // cell changed and moved
                        cellChanges.deletes.append(IndexPath(row: oldCellItem.index, section: sectionIndex))
                        cellChanges.inserts.append(IndexPath(row: newCellItem.index, section: sectionIndex))
                    }
                }
            } else if let oldCellItem = oldCellItem {
                cellChanges.deletes.append(IndexPath(row: oldCellItem.index, section: oldSectionItem.index))
            } else if let newCellItem = newCellItem {
                cellChanges.inserts.append(IndexPath(row: newCellItem.index, section: newSectionItem.index))
            }
        }
    }
}
