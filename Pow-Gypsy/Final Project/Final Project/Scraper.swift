//
//  Scraper.swift
//  Final Project
//
//  Created by user190282 on 4/19/21.
//

import Foundation

public class Scraper {
    
    var resort: String?

    
    // returns an array of floats of length 21 (7-days w/ am. pm. night.)
    func getData(completion: @escaping ([Float]) -> () )  {
        
        print("in get data")
        let url = URL(string: "https://www.snow-forecast.com/resorts/\(resort!)/6day/mid")!
        print(url)
        
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            
            let snowString = String(data: data, encoding: .utf8)!
            let listSnow = self.matches(for: "data-conv-imperial=\"(.*?)\"", in: snowString )
         
            var snowD:  [Float] = []
            for word in listSnow {
                
                var match = self.matches(for: "\"([^\"]*)\"", in: word)
                
                var num = match[0].dropFirst(1).dropLast(1)
                
                if match[0] != "-" {
                    snowD.append(Float(num) ?? 0.0)
                }
            }
            
            return completion(snowD)
        }
        
        task.resume()
    
        
    }
    
    
    func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}
