//
//  ViewController.swift
//  Final Project
//
//  Created by user190282 on 4/13/21.
//

import UIKit
import CoreData


class ViewController: UIViewController {
  

    @IBOutlet weak var resortLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    var scraper: Scraper?
    
    let pickerResorts = ["49 Degrees North", "Alpental", "Badger Mountain", "Bluewood", "Crystal Mountain", "Hurricane Ridge", "Loup Loup", "Mission Ridge", "Mount Baker", "Mt Spokane", "Stevens Pass", "Summit at Snoqualmie", "White Pass"]
    let resortURLs = ["Forty-Nine-Degrees-North", "Alpental-At-The-Summit", "BadgerMountain", "Bluewood", "Crystal-Mountain", "HurricaneRidge", "LoupLoup", "Mission-Ridge", "Mount-Baker", "Mt-Spokane-Ski-and-Snowboard-Park", "Stevens-Pass", "The-Summit-at-Snoqualmie", "White-Pass"]
    
    var resorts: [NSManagedObject] = []
    var managedObjectContext: NSManagedObjectContext!
    var appDelegate: AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = appDelegate.persistentContainer.viewContext
        pickerView.dataSource = self
        pickerView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        scraper = Scraper()
        resorts = fetchResorts()
        
       
    }
    @IBAction func addButtonPressed(_ sender: UIButton) {
        // if not in table view already, add it in
        
        // resortURL is for scraping
        let resortURL = resortURLs[pickerView.selectedRow(inComponent: 0)]
        for resort in resorts
        {
            let resortString = resort.value(forKey: "resort") as? String
            if resortString == resortLabel.text!
            {
                return
            }
        }
        
        // Reached here, then not in the table, add to table Core Data
        insertResort(resort: resortLabel.text!, resortURL: resortURL)
        self.tableView.reloadData()
        
    }
    
    
    // MARK: -Core Data
    func fetchResorts() -> [NSManagedObject] {
        
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Resort")
        var skiAreas: [NSManagedObject] = []
        do {
            skiAreas = try self.managedObjectContext.fetch(fetchRequest)
        } catch {
            print("getResorts error: \(error)")
        }
        return skiAreas
    }
    
    func insertResort(resort: String, resortURL: String)
    {
        let resortManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Resort", into: self.managedObjectContext)
        
        
        resortManagedObject.setValue(resort, forKey: "resort")
        resortManagedObject.setValue(resortURL, forKey: "resortURL")
        resortManagedObject.setValue(UUID().uuidString, forKey: "uuid")
        appDelegate.saveContext() // in AppDelegate.swift
        resorts.append(resortManagedObject)
    }
    
    func deleteResort(_ resort: NSManagedObject)
    {
        managedObjectContext.delete(resort)
        appDelegate.saveContext()
    }
    
    
    // MARK: - Schedule Notifications
    func  iterateSnowArray(snowArray: [Float], threshold: Int) -> (Float, Int)
    {
        for i in 0...(snowArray.count - 3) {
           // let j = i + 3
            var acc = Float(0.0)
            for j in i...i+2 {
                acc += snowArray[j]
            }
            
            if Int(acc) >= threshold {
                return (acc, i)
            }
        }
        return (-1,-1)
    }
    
    func scheduleNotification() {
        print("Scheduling notifications ")
        for resort in resorts {
            
            // Would check resorts time right here, but not sure when background fetch initially starts... so just doing one update a day
            
            // set Scraper.resortURL to current resorts URL
            let resortURL = resort.value(forKey: "resortURL")
            let threshold = resort.value(forKey: "threshold")
            print(resortURL!)
            scraper?.resort = resortURL! as! String
           
            // The URLSessiontask
            scraper?.getData() { snowArray in
                
                print("BACK snowData is \(snowArray)")
               
                var result = self.iterateSnowArray(snowArray: snowArray, threshold: threshold as! Int)
                print("Result, \(result)")
                if (result.0 != -1)
                {
                    let resortString = resort.value(forKey: "resort")!
                    print(resortString)
                    let resortUUID = resort.value(forKey: "uuid")
              
                    let content = UNMutableNotificationContent()
                    content.title = "Pow Gypsy"
                    content.body = "\(round(result.0*10) / 10) inches forecasted for \(resortString) in \(Int(result.1/3)) days.  Have fun out there if you can go!"
                    content.userInfo["id"] = resortUUID!
                    
                    // Configure trigger for 5 seconds from now
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0,
                                                                    repeats: false)
                    // Create request
                    let request = UNNotificationRequest(identifier: resortUUID! as! String,
                                                            content: content, trigger: trigger)
                    // Schedule request
                    let center = UNUserNotificationCenter.current()
                    center.add(request, withCompletionHandler: { (error) in
                        if let err = error {
                            print(err.localizedDescription)
                        }
                    })
                    
                }
                
                else {
                    
                    // This is here for testing purposes, as there is likely to be no new snowfall when this is ran. In a production scenario this else segment would be blank
                    let resortString = resort.value(forKey: "resort")!
                    print(resortString)
                    let resortUUID = resort.value(forKey: "uuid")
              
                    let content = UNMutableNotificationContent()
                    content.title = "Pow Gypsy"
                    content.body = "XX inches forecasted for \(resortString) in XX days.  Have fun out there if you can go!"
                    content.userInfo["id"] = resortUUID!
                    
                    // Configure trigger for 5 seconds from now
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0,
                                                                    repeats: false)
                    // Create request
                    let request = UNNotificationRequest(identifier: resortUUID! as! String,
                                                            content: content, trigger: trigger)
                    // Schedule request
                    let center = UNUserNotificationCenter.current()
                    center.add(request, withCompletionHandler: { (error) in
                        if let err = error {
                            print(err.localizedDescription)
                        }
                    })                      }
            }
            
            
            // Scraper.getData()ccccccccccccccccc
            // see if 3 contigous values of the array sum up to be higher than the threshold.  save the intial starting point of those values i, divide i by 3 and cast to int, that is the starting day of the snow (in i/3 days)
           
        }
      
    }
    
    @objc func settingsChanged (notification: Notification) {
        print("settings changed")
    }
    
}


// MARK: - Picker view
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerResorts[row]
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerResorts.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        resortLabel.text = pickerResorts[row]
    }
    
}


// MARK: - Table data

extension  ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resorts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath)

        // Configure the cell...
        let resort = resorts[indexPath.row]
        cell.textLabel?.text = resort.value(forKey: "resort") as? String
        
        
        //
        //cell.textLabel?.text = quotation.quote
       // if let auth = quotation.author {
       //     cell.detailTextLabel?.text = auth
       // } else {
       //     cell.detailTextLabel?.text = "Anonymous"
      //  }
       return cell
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let resortMO = resorts[indexPath.row]
            resorts.remove(at: indexPath.row)
            deleteResort(resortMO)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        //} else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "toSettings" {
            let vc = segue.destination as! SettingsViewControllor
            let index = self.tableView.indexPathForSelectedRow?.row
            vc.appDelegate = self.appDelegate
            vc.managedObjectContext = self.managedObjectContext
            vc.resort = self.resorts[index!]
        }
      /*  if segue.identifier == "toDetailView" {
            let vc = segue.destination as! DetailViewController
            let index = self.tableView.indexPathForSelectedRow?.row
            vc.quotation = Quotation(quote: "placeholder")
            vc.quotation?.quote = quotations[index!].value(forKey: "quote") as? String ?? ""
            vc.quotation?.author = quotations[index!].value(forKey: "author") as? String ?? "Anonymous"
        }*/
    }
    
    @IBAction func unwindToMainView(segue: UIStoryboardSegue) {
   
    }
    
}
