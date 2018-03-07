//
//  TableViewAnimationsTests.swift
//  TableViewAnimationsTests
//
//  Created by Stanislav Ostrovskiy on 3/3/18.
//  Copyright © 2018 Stanislav Ostrovskiy. All rights reserved.
//

import TableViewAnimations
import XCTest
@testable import TableViewAnimations

class TableViewAnimationsTests: XCTestCase {
    
    var items: [DataModelSection]!
    
    override func setUp() {
        super.setUp()
        
        items = initialData()
    }
    
    override func tearDown() {
        items = nil
        super.tearDown()
    }
    
    func testNoChanges() {
        let oldData = flatten(data: items)
        let newData = flatten(data: items)
        
        let changes = DiffCalculator.calculate(oldItems: oldData, newItems: newData)
        
        let expectedChanges = SectionChanges()
        
        XCTAssertTrue(changes == expectedChanges)
    }
    
    func testDeleteSection() {
        var newItems = initialData()
        newItems.remove(at: 2)

        let oldData = flatten(data: items)
        let newData = flatten(data: newItems)
        let changes = DiffCalculator.calculate(oldItems: oldData, newItems: newData)
        
        let expectedChanges = SectionChanges(inserts: [], deletes: [2])
        
        XCTAssertTrue(changes == expectedChanges)
    }
    
    func testInsertSection() {
        items.remove(at: 0)
        
        let newItems = initialData()

        let oldData = flatten(data: items)
        let newData = flatten(data: newItems)
        
        let changes = DiffCalculator.calculate(oldItems: oldData, newItems: newData)
        
        let expectedChanges = SectionChanges(inserts: [0], deletes: [], moves: [(from: 0, to: 1), (from: 1, to: 2)])
        
        XCTAssertTrue(changes == expectedChanges)
    }
    
    func testInsertSectionAndDeleteSection() {
        var newItems = initialData()
        newItems.remove(at: 0)
        newItems.append(DataModelSection(id: "5", cells: [ DataSourceModelItem(id: "key7", value: "value10")]))
        
        let oldData = flatten(data: items)
        let newData = flatten(data: newItems)
        
        let changes = DiffCalculator.calculate(oldItems: oldData, newItems: newData)
        
        let expectedChanges = SectionChanges(inserts: [2], deletes: [0], moves: [(from: 1, to: 0), (from: 2, to: 1)])
        
        XCTAssertTrue(changes == expectedChanges)
    }
    
    func testDeleteCell() {
        let oldData = flatten(data: items)
        
        let item1 = DataSourceModelItem(id: "key1", value: "value1")
        let item3 = DataSourceModelItem(id: "key3", value: "value3")
        let item4 = DataSourceModelItem(id: "key4", value: "value4")
        let item5 = DataSourceModelItem(id: "key5", value: "value5")
        let item6 = DataSourceModelItem(id: "key6", value: "value6")
        
        let section1 = DataModelSection(id: "1", cells: [item1])
        let section2 = DataModelSection(id: "2", cells: [item3, item4])
        let section3 = DataModelSection(id: "3", cells: [item5, item6])
        
        let newData = flatten(data: [section1, section2, section3])
        
        let changes = DiffCalculator.calculate(oldItems: oldData, newItems: newData)
        
        let expectedCellChanges = CellChanges(inserts: [], deletes: [IndexPath(row: 1, section: 0)], reloads: [])
        let expectedChanges = SectionChanges(inserts: [], deletes: [], updates: expectedCellChanges)
        
        XCTAssertTrue(changes == expectedChanges)
    }
    
    private func initialData() -> [DataModelSection] {
        let item1 = DataSourceModelItem(id: "key1", value: "value1")
        let item2 = DataSourceModelItem(id: "key2", value: "value2")
        let item3 = DataSourceModelItem(id: "key3", value: "value3")
        let item4 = DataSourceModelItem(id: "key4", value: "value4")
        let item5 = DataSourceModelItem(id: "key5", value: "value5")
        let item6 = DataSourceModelItem(id: "key6", value: "value6")
        
        let section1 = DataModelSection(id: "1", cells: [item1, item2])
        let section2 = DataModelSection(id: "2", cells: [item3, item4])
        let section3 = DataModelSection(id: "3", cells: [item5, item6])
        
        return [section1, section2, section3]
    }
    
    private func flatten(data: [DataModelSection]) -> [ReloadableSection<String>] {
        return data.enumerated().map { ReloadableSection(key: $0.element.id, value: $0.element.cells.enumerated().map { ReloadableCell(key: $0.element.id, value: $0.element.value, index: $0.offset) }, index: $0.offset) }
    }
}
