//
//  ShareViewController.swift
//  traQShareExtension
//
//  Created by Yoya Mesaki on 2019/09/19.
//

import UIKit
import Social
import MobileCoreServices

struct MessageRequest: Codable {
    let text: String
}

struct ChannelResponse: Codable {
    let channelId: String
    let name: String
    let member: [String]?
    let parent: String
    let topic: String
    let children: [String]?
    let visibility: Bool
    let force: Bool
    let privateChannel: Bool
    let dm: Bool
    
    enum CodingKeys: String, CodingKey {
        case channelId
        case name
        case member
        case parent
        case topic
        case children
        case visibility
        case force
        case privateChannel = "private"
        case dm
    }
}

enum traQShareError: Error {
    case noChannelSelected
}

class ShareViewController: SLComposeServiceViewController, traQChannelTableDelegate {
    
    private let suiteName = "group.tech.trapti.traQ"
    private let sessionKey = "traq_session"
    private let channelNameKey = "traq_share_channel_name"
    private let channelIdKey = "traq_share_channel_id"
    
    private let sessionCookieName = "r_session"
    
    private let apiRoot = "https://q.trap.jp/api/1.0"
    private let channelIdPlaceholder = "{channelID}"
    private let postMessageUrl = "/channels/{channelID}/messages?embed=1"
    private let getChannelsUrl = "/channels"
    private let getStarsUrl = "/users/me/stars"
    
    private var session: String?
    private var channelName: String?
    private var channelId: String?
    
    private var channels: [ChannelResponse] = []
    private var channelsDict: [String:ChannelResponse] = [:]
    private var staredChannelIds: [String] = []
    private var staredChannelPathDict: [String:String] = [:]
    
    private var hasChannelLoaded = false
    
    private func createRequest(method: String, endpoint: String) -> URLRequest {
        var request = URLRequest(url: URL(string: self.apiRoot + endpoint)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(self.sessionCookieName)=\(self.session ?? "")", forHTTPHeaderField: "cookie")
        return request
    }
    
    private func loadSettings() {
        guard let userDefaults = UserDefaults(suiteName: self.suiteName) else {
            return
        }
        self.session = userDefaults.string(forKey: self.sessionKey)
        self.channelName = userDefaults.string(forKey: self.channelNameKey)
        self.channelId = userDefaults.string(forKey: self.channelIdKey)
    }
    
    private func saveSettings() {
        guard let userDefaults = UserDefaults(suiteName: self.suiteName) else {
            return
        }
        userDefaults.set(self.channelName, forKey: self.channelNameKey)
        userDefaults.set(self.channelId, forKey: self.channelIdKey)
        userDefaults.synchronize()
    }

    
    private func processChannelsResponse<T: Decodable>(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> [T] {
        guard let response =
            response as? HTTPURLResponse,
            (200...299).contains(response.statusCode),
            data != nil
        else {
            print ("server error")
            return []
        }
        do {
            return try JSONDecoder().decode([T].self, from: data!)
        }
        catch {
            print ("decode failed")
            return []
        }
    }
    
    private func getChannelFullPath(_ channelId: String) -> String {
        var path = ""
        var parentId = channelId
        while parentId != "", let parentChannel = self.channelsDict[parentId] {
            path = parentChannel.name + "/" + path
            parentId = parentChannel.parent
        }
        return "#" + path.dropLast(1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let frame = self.view.frame
        let newSize:CGSize = CGSize(width:frame.size.width, height:frame.size.height * 2)
        self.preferredContentSize = newSize
        
        self.loadSettings()
        
        let starRequest = self.createRequest(method: "GET", endpoint: self.getStarsUrl)
        let channelsRequest = self.createRequest(method: "GET", endpoint: self.getChannelsUrl)
        
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        
        dispatchGroup.enter()
        dispatchQueue.async(group: dispatchGroup) {
            URLSession.shared.dataTask(with: channelsRequest) { data, response, error in
                self.channels = self.processChannelsResponse(data, response, error)
                self.channels.forEach { channel in
                    self.channelsDict[channel.channelId] = channel
                }
                dispatchGroup.leave()
            }.resume()
        }
        
        dispatchGroup.enter()
        dispatchQueue.async(group: dispatchGroup) {
            URLSession.shared.dataTask(with: starRequest) { data, response, error in
                self.staredChannelIds = self.processChannelsResponse(data, response, error)
                dispatchGroup.leave()
            }.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.staredChannelIds.forEach { channelId in
                self.staredChannelPathDict[channelId] = self.getChannelFullPath(channelId)
            }
            self.hasChannelLoaded = true
            self.validateContent()
        }
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        
        // チャンネル選択済みかもここでバリデーションしてしまう
        if (self.channelId == nil) {
            return false
        }
            
        self.charactersRemaining = self.contentText.count as NSNumber
        
        let canPost: Bool = self.contentText.count > 0
        if canPost {
            return true
        }
        
        return false
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        guard let channelId = self.channelId else {
            self.extensionContext!.cancelRequest(withError: traQShareError.noChannelSelected)
            return
        }
        
        let extensionItem: NSExtensionItem = self.extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = extensionItem.attachments?.first!
        
        let propertyList = String(kUTTypePropertyList)
        
        let content = self.contentText
        
        
        if itemProvider?.hasItemConformingToTypeIdentifier(propertyList) ?? false {
            itemProvider!.loadItem(forTypeIdentifier: propertyList, options: nil, completionHandler: { (item, error) -> Void in
                let dictionary = item as! NSDictionary
                OperationQueue.main.addOperation {
                    let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! NSDictionary
                    let title = results["title"] as! String
                    let url = results["url"] as! String
                    
                    // POSTする
                    let message = MessageRequest(text: "\(content ?? "")\n[\(title)](\(url))")
                    let endpoint = self.postMessageUrl.replacingOccurrences(of: self.channelIdPlaceholder, with: channelId)
                    
                    guard let uploadData = try? JSONEncoder().encode(message) else {
                        return
                    }
                    
                    let request = self.createRequest(method: "POST", endpoint: endpoint)

                    let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
                        if let error = error {
                            print ("error: \(error)")
                            return
                        }
                        guard let response =
                            response as? HTTPURLResponse,
                            (200...299).contains(response.statusCode) else {
                            print ("server error")
                            return
                        }
                    }
                    task.resume()
                    
                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)

                }
            })
        }
        
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        // self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        var items = [SLComposeSheetConfigurationItem]()
        
        //共有するチャンネルの設定
        if let item = SLComposeSheetConfigurationItem() {
            item.title = "チャンネル"
            item.value = self.channelName ?? "チャンネルを選択"
            item.tapHandler = {
                let vc = ShareChannelViewController()
                vc.delegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            }
            items.append(item)
        }
        
        return items
    }
    
    func tableContentCount() -> Int {
        return self.staredChannelIds.count
    }
    func tableContent(cellForRowAt indexPath: IndexPath) -> String {
        let id = self.staredChannelIds[indexPath.row]
        return self.staredChannelPathDict[id] ?? ""
    }
    func tableContent(didSelectRowAt indexPath: IndexPath) {
        let id = self.staredChannelIds[indexPath.row]
        self.channelId = id
        self.channelName = self.staredChannelPathDict[id] ?? ""
        self.saveSettings()
        self.reloadConfigurationItems()
        self.validateContent()
    }
}
