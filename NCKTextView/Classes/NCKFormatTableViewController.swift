//
//  NCKFormatTableViewController.swift
//  Pods
//
//  Created by Chanricle King on 29/08/2016.
//
//

import UIKit

class NCKFormatTableViewController: UITableViewController {

    @IBOutlet var cells: [UITableViewCell]!
    
    typealias SelectionCompletion = (NCKInputParagraphType) -> Void
    
    var selectedCompletion: SelectionCompletion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if selectedCompletion != nil {
            selectedCompletion!(NCKInputParagraphType(rawValue: indexPath.row)!)
        }
        
        /*
        cells.forEach { $0.accessoryType = .None }
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        */
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
