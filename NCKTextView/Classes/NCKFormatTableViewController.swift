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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedCompletion != nil {
            selectedCompletion!(NCKInputParagraphType(rawValue: indexPath.row)!)
            
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
