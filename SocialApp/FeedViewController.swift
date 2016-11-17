//
//  FeedViewController.swift
//  SocialApp
//
//  Created by Joshua Schipull on 11/6/16.
//  Copyright © 2016 Joshua Schipull. All rights reserved.
//

import UIKit
import Accounts
import Social

class FeedViewController: UITableViewController {

    var selectedAccount : ACAccount!
    var tweets : NSMutableArray?
    var imageCache : NSCache<AnyObject, AnyObject>?
    var queue : OperationQueue?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userDefaults = UserDefaults.standard
        let accountData = userDefaults.object(forKey: "selectedAccount") as! NSData
        selectedAccount = NSKeyedUnarchiver.unarchiveObject(with: accountData as Data) as! ACAccount
        
        self.tabBarController?.navigationItem.title = selectedAccount.accountDescription
        self.tabBarController?.edgesForExtendedLayout = []
        
        queue = OperationQueue()
        queue!.maxConcurrentOperationCount = 4
        
        retrieveTweets()
    }
    
    func retrieveTweets(){
        tweets?.removeAllObjects()
        
        if let account = selectedAccount {
            let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")
            
            let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, url: requestURL as URL!, parameters: nil)
            
            request?.account = account
           // let handler: SLRequestHandler = {(response, urlResponse, error) in
                
           //     if(urlResponse?.statusCode == 200)
           //     {
           //         var jsonParseError : NSError?
           //         self.tweets = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSMutableArray
           //     }
                
            //    DispatchQueue.main.async { self.tableView.reloadData() }
           // }
            request?.perform(handler: {(responseData, urlResponse, error) in
                
                do {
                    try self.tweets = JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSMutableArray
                    
                    DispatchQueue.main.async() {self.tableView.reloadData()}
                    
                } catch let error as NSError {
                    print("Data serialization error: \(error.localizedDescription)")
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        
        if let tweetCount = self.tweets?.count {
            return tweetCount
        }
        else
        {
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell", for: indexPath) as! TweetCell

        let tweetData = tweets?.object(at: indexPath.row) as! NSDictionary
        let userData = tweetData.object(forKey: "user") as! NSDictionary
        
        cell.tweetContent.text? = tweetData.object(forKey: "text") as! String
        cell.tweetUserName.text? = userData.object(forKey: "name") as! String
        
        let imageURLString = userData.object(forKey: "profile_image_url") as! String
        let image = imageCache?.object(forKey: imageURLString as AnyObject) as! UIImage?
        
        if let cachedImage = image {
            cell.tweetUserAvatar.image = cachedImage
        }
        else
        {
            cell.tweetUserAvatar.image = UIImage(named: "camera.png")!
            
            queue?.addOperation() {
                let imageURL = NSURL(string: imageURLString) as NSURL!
                let imageData = NSData(contentsOf: imageURL as! URL) as NSData?
                let image = UIImage(data: imageData! as Data) as UIImage?
                
                if let downloadedImage = image {
                    OperationQueue.main.addOperation(){
                        let cell = tableView.cellForRow(at: indexPath) as! TweetCell
                        
                        cell.tweetUserAvatar.image = downloadedImage
                        
                    }
                    
                    self.imageCache?.setObject(downloadedImage, forKey: imageURLString as AnyObject)
                }
            }
            
        }

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "ComposeTweet")
        {
            let targetController = segue.destination as! ComposeViewController
            
            targetController.selectedAccount = selectedAccount
        }
        else if(segue.identifier == "ShowTweet")
        {
            let path : NSIndexPath = self.tableView.indexPathForSelectedRow! as NSIndexPath
            
            let tweetData = self.tweets!.object(at: path.row) as! NSDictionary
            
            let targetController = segue.destination as! TweetViewController
            
            targetController.selectedTweet = tweetData
            
        }
    }

}
