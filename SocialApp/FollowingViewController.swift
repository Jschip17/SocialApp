//
//  FollowingViewController.swift
//  SocialApp
//
//  Created by Joshua Schipull on 11/16/16.
//  Copyright © 2016 Joshua Schipull. All rights reserved.
//

import UIKit
import Accounts
import Social

private let reuseIdentifier = "Cell"

class FollowingViewController: UICollectionViewController {

    var following : NSMutableArray?
    var imageCache : NSCache<AnyObject, AnyObject>?
    var queue : OperationQueue?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        queue = OperationQueue()
        queue?.maxConcurrentOperationCount = 4
        
        self.tabBarController?.navigationItem.title = "Following"
        
        retrieveUsers()
        
    }
    
    func retrieveUsers(){
        following?.removeAllObjects()
        
        let userDefaults = UserDefaults.standard
        let accountData = userDefaults.object(forKey: "selectedAccount") as! NSData
        let selectedAccount = NSKeyedUnarchiver.unarchiveObject(with: accountData as Data) as! ACAccount
        
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/friends/list.json?count=200")
        
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, url: requestURL as URL!, parameters: nil)
        
        request?.account = selectedAccount
        
        request?.perform(handler: {(responseData, urlResponse, error) in
            
            do {
                let followingData = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                self.following = followingData?.object(forKey: "users") as? NSMutableArray
                
                DispatchQueue.main.async() {self.collectionView?.reloadData()}
                
            } catch let error as NSError {
                print("Data serialization error: \(error.localizedDescription)")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        //  return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //  return the number of items
        if let followCount = following?.count{
            return followCount
        }
        else
        {
         return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        let userData = following?.object(at: indexPath.row) as! NSDictionary
        let imageURLString = userData.object(forKey: "profile_image_url") as! String
        
        if let image = imageCache?.object(forKey: imageURLString as AnyObject) as? UIImage{
            let imageView = UIImageView(image: image) as UIImageView
            imageView.bounds = cell.frame
            cell.addSubview(imageView)
        }
        else
        {
            queue?.addOperation(){
                let imageURL = NSURL(string: imageURLString) as NSURL?
                let imageData = NSData(contentsOf: imageURL! as URL) as NSData?
                let image = UIImage(data: imageData! as Data) as UIImage?
                
                if image != nil{
                    OperationQueue.main.addOperation(){
                        let imageView = UIImageView(image: image)
                        imageView.bounds = cell.frame
                        
                        if let cell = self.collectionView?.cellForItem(at: indexPath) as UICollectionViewCell!{
                            cell.addSubview(imageView)
                        }
                    }
                    self.imageCache?.setObject(image!, forKey: imageURLString as AnyObject)
                }
            }
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
