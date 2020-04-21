//
//  ShareChannelViewController.swift
//  traQShareExtension
//
//  Created by Yoya Mesaki on 2019/09/27.
//

import Foundation
import UIKit

protocol traQChannelTableDelegate {
    func tableContentCount() -> Int
    func tableContent(cellForRowAt indexPath: IndexPath) -> String
    func tableContent(didSelectRowAt indexPath: IndexPath)
}

class ShareChannelViewController: UITableViewController {
    
    var delegate: traQChannelTableDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.clear
        edgesForExtendedLayout = []
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.tableContentCount() ?? 0
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = self.delegate?.tableContent(cellForRowAt: indexPath)
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.tableContent(didSelectRowAt: indexPath)
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
}
