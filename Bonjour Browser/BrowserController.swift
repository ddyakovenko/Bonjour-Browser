//
//  BrowserController.swift
//  Bonjour Browser
//

import UIKit

private let reuseIdentifier = "Cell"
private let netServiceType = "_http._tcp"

class BrowserController: UITableViewController {

    var isStarted: Bool { return netBrowser != nil }
    
    private(set) var services: Array<NetService> = Array()
    private(set) var netBrowser: NetServiceBrowser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: .UIApplicationWillResignActive, object: nil)
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        searchForServices()
    }
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        stopSearching()
    }
    
    func searchForServices() {
        guard !isStarted else { return }
        
        let browser = NetServiceBrowser()
        browser.delegate = self
        browser.schedule(in: .current, forMode: .defaultRunLoopMode)
        browser.searchForServices(ofType: netServiceType, inDomain: "")
        
        netBrowser = browser
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func stopSearching() {
        guard let browser = netBrowser else { return }
        browser.delegate = nil
        browser.stop()
        
        netBrowser = nil
        
        services.removeAll()
        
        tableView.reloadData()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

// MARK: - UITableViewDataSource -

extension BrowserController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let service = services[indexPath.row]
        
        cell.textLabel?.text = service.name
        
        return cell
    }
}

// MARK: - NetServiceBrowserDelegate -

extension BrowserController: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard browser == netBrowser, !moreComing else { return }
        
        services.append(service)
        
        tableView.reloadData()
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        guard browser == netBrowser, !moreComing else { return }
        
        if let index = services.index(where: { $0 == service }) {
            services.remove(at: index)
            
            tableView.reloadData()
        }
    }
}
