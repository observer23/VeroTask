//
//  TaskManager.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import Foundation
import CoreData
class TaskManager {
    static let shared = TaskManager()
    private init() {}
    
    func syncTasksFromAPI(completion: @escaping ([TaskModel]?, String?) -> Void) {
        // Check internet connectivity
        guard NetworkManager.shared.isConnectedToInternet() else {
            fetchTasksFromCoreData { tasks in
                completion(tasks,"No internet connection. Fetching tasks from local database." ) // Return local tasks if offline
            }
            return
        }
        // Perform login and fetch tasks from API
        NetworkManager.shared.login { result in
            switch result {
            case .success:
                NetworkManager.shared.fetchTasksFromAPI { [weak self] tasksResult in
                    switch tasksResult {
                    case .success(let tasks):
                        // Save tasks to CoreData in background
                        self?.saveTasksToCoreData(tasks: tasks)
                        self?.fetchTasksFromCoreData { savedTasks in
                            completion(savedTasks, nil) // Return updated tasks
                        }
                    case .failure(let error):
                        print("Error fetching tasks: \(error.localizedDescription)")
                        completion(nil, error.localizedDescription)
                    }
                }
            case .failure(let error):
                print("Login failed: \(error)")
                completion(nil, error.localizedDescription)
            }
        }
    }
    // Fetch tasks from CoreData
    func fetchTasksFromCoreData(completion: @escaping ([TaskModel]) -> Void) {
        let backgroundContext = CoreDataManager.shared.context
        
        backgroundContext.perform {
            do {
                let fetchRequest: NSFetchRequest<TaskModel> = TaskModel.fetchRequest()
                let tasks = try backgroundContext.fetch(fetchRequest)
                
                DispatchQueue.main.async {
                    completion(tasks)
                }
            } catch {
                print("Error fetching tasks: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    // Save tasks to CoreData
    func saveTasksToCoreData(tasks: [Task]) {
        let backgroundContext = CoreDataManager.shared.backgroundContext
        
        backgroundContext.perform {
            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TaskModel.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try backgroundContext.execute(deleteRequest)

                
                for task in tasks {
                    let taskModel = TaskModel(context: backgroundContext)
                    taskModel.title = task.title
                    taskModel.taskDescription = task.description
                    taskModel.colorCode = task.colorCode
                    taskModel.createdDate = Date()
                    print(taskModel)
                }
                
                try backgroundContext.save()
            } catch {
                print("Error saving tasks to CoreData: \(error)")
            }
        }
    }
    // Delete all tasks
    func deleteAllTasks() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TaskModel.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            CoreDataManager.shared.saveContext()
        } catch {
            print("Error deleting tasks: \(error)")
        }
    }
}
