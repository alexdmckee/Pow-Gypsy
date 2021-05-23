//
//  SettingsViewController.swift
//  Final Project
//
//  Created by user190282 on 4/15/21.
//

import Foundation
import UIKit
import CoreData

class SettingsViewControllor: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var headingLabel: UILabel!
    
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    
    @IBOutlet weak var morningNotificationSwitch: UISwitch!
    @IBOutlet weak var afternoonNotificationSwitch: UISwitch!
    @IBOutlet weak var eveningNotificationSwitch: UISwitch!
    
    var resort: NSManagedObject?
    var managedObjectContext: NSManagedObjectContext!
    var appDelegate: AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        headingLabel.text = (resort?.value(forKey: "resort") as! String)
        let level = resort?.value(forKey: "threshold")
        thresholdLabel.text = "\(level!)"
        
        slider.value = Float(thresholdLabel.text!)!
    
        
        setSwitches()
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let rounded = Int(slider.value)
        thresholdLabel.text = "\(rounded)"
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // save new limit
        let newLimit = Int(thresholdLabel.text!)
        resort?.setValue(newLimit, forKey: "threshold")
        
        // get switches saved into core data
        saveSwitches()
        appDelegate.saveContext()
        performSegue(withIdentifier: "unwindToMainView", sender: self)
        
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToMainView", sender: self)
        
    }
    
    func saveSwitches()
    {
        var morning = resort?.value(forKey: "morningNotification")
        var midday = resort?.value(forKey: "afternoonNotification")
        var evening = resort?.value(forKey: "eveningNotification")
        
        if morning! as! Bool != morningNotificationSwitch.isOn {
            morning = !(morning! as! Bool)
            resort?.setValue(morning, forKey: "morningNotification")
        }
        
        if midday! as! Bool != afternoonNotificationSwitch.isOn {
            midday = !(midday as! Bool)
            resort?.setValue(midday, forKey: "afternoonNotification")
        }
        
        if evening! as! Bool != eveningNotificationSwitch.isOn {
            evening = !(evening as! Bool)
            resort?.setValue(evening, forKey: "eveningNotification")
        }
    }
    
    func setSwitches()
    {
       
        if let mn = resort?.value(forKey: "morningNotification") {
            if mn as! Bool == true {
                self.morningNotificationSwitch.isOn = true
            }
            
            else {
                self.morningNotificationSwitch.isOn = false
            }
        }
        
        if let mn = resort?.value(forKey: "afternoonNotification") {
            if mn as! Bool == true {
                self.afternoonNotificationSwitch.isOn = true
            }
            else {
                self.afternoonNotificationSwitch.isOn = false            }
        }
        
        if let mn = resort?.value(forKey: "eveningNotification") {
            if mn as! Bool == true {
                self.eveningNotificationSwitch.isOn = true
            }
            else {
                self.eveningNotificationSwitch.isOn = false            }
        }
        
    }
}
