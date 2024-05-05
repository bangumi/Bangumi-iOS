//
//  BackgroundActor.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/3.
//

import Foundation
import SwiftData

/// ```swift
///  // It is important that this actor works as a mutex,
///  // so you must have one instance of the Actor for one container
//   // for it to work correctly.
///  let actor = BackgroundActor(container: modelContainer)
///
///  Task {
///      let data: [MyModel] = try? await actor.fetchData()
///  }
///  ```
@available(iOS 17, *)
public actor BackgroundActor {
  public let modelContainer: ModelContainer
  public let modelExecutor: any ModelExecutor
  private var context: ModelContext { modelExecutor.modelContext }

  public init(container: ModelContainer) {
    self.modelContainer = container
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    modelExecutor = DefaultSerialModelExecutor(modelContext: context)
  }

  public func fetchOne<T: PersistentModel>(
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = []
  ) throws -> T? {
    var fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
    fetchDescriptor.fetchLimit = 1
    let list: [T] = try context.fetch(fetchDescriptor)
    return list.first
  }

  public func fetchData<T: PersistentModel>(
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = [],
    limit: Int? = nil,
    offset: Int? = nil
  ) throws -> [T] {
    var fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
    fetchDescriptor.fetchLimit = limit
    fetchDescriptor.fetchOffset = offset
    let list: [T] = try context.fetch(fetchDescriptor)
    return list
  }

  public func fetchData<T: PersistentModel>(descriptor: FetchDescriptor<T>) throws -> [T] {
    let list: [T] = try context.fetch(descriptor)
    return list
  }

  public func fetchCount<T: PersistentModel>(
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = []
  ) throws -> Int {
    let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
    let count = try context.fetchCount(fetchDescriptor)
    return count
  }

  public func insert<T: PersistentModel>(data: T, background: Bool = true) {
    let context = background ? context : data.modelContext ?? context
    context.insert(data)
  }

  public func delete<T: PersistentModel>(data: T, background: Bool = true) {
    let context = background ? context : data.modelContext ?? context
    context.delete(data)
  }

  public func save() throws {
    try context.save()
  }

  public func remove<T: PersistentModel>(predicate: Predicate<T>? = nil) throws {
    try context.delete(model: T.self, where: predicate)
  }

  public func saveAndInsertIfNeeded<T: PersistentModel>(
    data: T,
    predicate: Predicate<T>,
    background: Bool = true
  ) throws {
    let descriptor = FetchDescriptor<T>(predicate: predicate)
    let context = background ? context : data.modelContext ?? context
    let savedCount = try context.fetchCount(descriptor)
    if savedCount == 0 {
      context.insert(data)
    }
    try context.save()
  }

  func insertBatch<T: PersistentModel>(data: [T]) throws {
    for row in data {
      context.insert(row)
    }
    try context.save()
  }
}
