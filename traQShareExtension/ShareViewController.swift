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
    let content: String
    let embed: Bool?
}

struct Channel: Codable {
    let id: String
    let parentId: String?
    let visibility: Bool
    let force: Bool
    let topic: String
    let name: String
    let children: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case parentId
        case visibility
        case force
        case topic
        case name
        case children
    }
}

struct DMChannel: Codable {
    let id: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
    }
}


struct ChannelResponse: Codable {
    let publicChannels: [Channel]
    let dm: [DMChannel]?
    enum CodingKeys: String, CodingKey {
        case publicChannels = "public"
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
    
    private var apiRoot = "https://q.trap.jp/api/v3"
    private let channelIdPlaceholder = "{channelID}"
    private let postMessageUrl = "/channels/{channelID}/messages"
    private let getChannelsUrl = "/channels"
    private let getStarsUrl = "/users/me/stars"
    
    private var session: String?
    private var channelName: String?
    private var channelId: String?
    
    private var channels: [Channel] = []
    private var channelsDict: [String:Channel] = [:]
    private var staredChannelIds: [String] = []
    private var staredChannelPathDict: [String:String] = [:]
    
    private var hasChannelLoaded = false
        
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // 2020-05-01T00:00:00+09:00
        if (Date() < Date.init(timeIntervalSince1970: 1588258800)) {
            apiRoot = "https://traq-s-dev.tokyotech.org/api/v3"
        }
    }
        
    private func createRequest(method: String, endpoint: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: self.apiRoot + endpoint)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(self.sessionCookieName)=\(self.session ?? "")", forHTTPHeaderField: "cookie")
        if body != nil {
            request.httpBody = body!
        }
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

    
    private func processChannelsResponse<T: Decodable>(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> T? {
        guard let response =
            response as? HTTPURLResponse,
            (200...299).contains(response.statusCode),
            data != nil
        else {
            print ("server error")
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data!)
        }
        catch let err {
            print ("decode failed")
            print(err)
            return nil
        }
    }
    
    private func getChannelFullPath(_ channelId: String) -> String {
        var path = ""
        var parentId = channelId
        while parentId != "", let parentChannel = self.channelsDict[parentId] {
            path = parentChannel.name + "/" + path
            let nextPparentId = channelsDict[parentId]?.id ?? ""
            if (nextPparentId == parentId) {
                break
            }
            parentId = nextPparentId
        }
        return "#" + path.dropLast(1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let frame = self.view.frame
        let newSize:CGSize = CGSize(width:frame.size.width, height:frame.size.height * 2)
        preferredContentSize = newSize
        
        loadSettings()
        
        let starRequest = createRequest(method: "GET", endpoint: self.getStarsUrl)
        let channelsRequest = createRequest(method: "GET", endpoint: self.getChannelsUrl)
        
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        
        dispatchGroup.enter()
        dispatchQueue.async(group: dispatchGroup) {
            URLSession.shared.dataTask(with: channelsRequest) { data, response, error in
                let resultOrNil: ChannelResponse? = self.processChannelsResponse(data, response, error)
                if let result = resultOrNil  {
                    self.channels = result.publicChannels
                    self.channels.forEach { channel in
                        self.channelsDict[channel.id] = channel
                    }
                }
                dispatchGroup.leave()
            }.resume()
        }
        
        dispatchGroup.enter()
        dispatchQueue.async(group: dispatchGroup) {
            URLSession.shared.dataTask(with: starRequest) { data, response, error in
                let staredChannelIdsOrNil: [String]? = self.processChannelsResponse(data, response, error)
                if let staredChannelIds = staredChannelIdsOrNil {
                    self.staredChannelIds = staredChannelIds
                }
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
                    let message = MessageRequest(content: "\(content ?? "")\n[\(title)](\(url))", embed: true)
                    let endpoint = self.postMessageUrl.replacingOccurrences(of: self.channelIdPlaceholder, with: channelId)
                    
                    guard let uploadData = try? JSONEncoder().encode(message) else {
                        return
                    }
                    
                    let request = self.createRequest(method: "POST", endpoint: endpoint, body: uploadData)

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
