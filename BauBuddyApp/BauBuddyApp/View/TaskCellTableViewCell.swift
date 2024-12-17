//
//  TaskCellTableViewCell.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import UIKit

class TaskCellTableViewCell: UITableViewCell {

    @IBOutlet var background: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        background.layer.cornerRadius = 15
        background.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    func configure(with task: TaskModel) {
        titleLabel.text = task.title
        descriptionLabel.text = task.taskDescription
        background.backgroundColor = UIColor(hexString: task.colorCode ?? "#00000")
    }
}
