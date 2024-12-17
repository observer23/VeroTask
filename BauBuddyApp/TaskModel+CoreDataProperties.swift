//
//  TaskModel+CoreDataProperties.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 16.12.2024.
//
//

import Foundation
import CoreData


extension TaskModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskModel> {
        return NSFetchRequest<TaskModel>(entityName: "TaskModel")
    }

    @NSManaged public var colorCode: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var taskDescription: String?
    @NSManaged public var title: String?

}

extension TaskModel : Identifiable {

}
