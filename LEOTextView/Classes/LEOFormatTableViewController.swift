//
//  LEOFormatTableViewController.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

class LEOFormatTableViewController: UITableViewController {

    @IBOutlet var cells: [UITableViewCell]!

    typealias SelectionCompletion = (LEOInputParagraphType) -> Void

    var selectedCompletion: SelectionCompletion?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedCompletion != nil {
            selectedCompletion!(LEOInputParagraphType(rawValue: indexPath.row)!)

        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}