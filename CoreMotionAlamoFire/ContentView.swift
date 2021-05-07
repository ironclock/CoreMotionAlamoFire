//
//  ContentView.swift
//  Sample App
//
//  Created by Jon Caceres on 5/6/21.
//
import SwiftUI
import Alamofire
import CoreMotion

struct ContentView: View {
    @ObservedObject var countryCont = CountryController()
    @State private var selection = ""
    @State public var choice = ""
    @State public var toggle: Bool = false;
    @State var steps: Int?
    @State public var different: Int?
    
    /*
     Call pedometer from CoreMotion.
     */
    let pedometer: CMPedometer = CMPedometer()
    
    /*
     Check to see if pedometer data is available
     */
    var isPedometerAvail: Bool {
        return CMPedometer.isPedometerEventTrackingAvailable() &&
            CMPedometer.isDistanceAvailable() && CMPedometer.isStepCountingAvailable()
    }
    
    func updateUI(data: CMPedometerData) {
        steps = data.numberOfSteps.intValue
    }

    /*
     This function initializes the pedometer data.
     It pulls the amount of steps over the past day
     from the user's device using CoreMotion.
     */
    func initializePedometer() {
        if isPedometerAvail {
            guard let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
                return
            }
            
        pedometer.queryPedometerData(from: startDate, to: Date()) { (data, error) in
           guard let data = data, error == nil else { return }
            steps = data.numberOfSteps.intValue
            updateUI(data: data)
            }
        }
    }
    
    /*
     A picker is displayed that pulls JSON data from below (using AF).
     Once a selection is made, it shows the associated step
     data associated with the selected country. It then
     compares that step data with the step data from your device
     using CoreMotion. (Note: this won't work in a simulator)
     */
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $selection, label: Text("Choose a Country")) {
                        ForEach(countryCont.countries) { country in
                            Text(country.country).tag(country.country)
                        }
                    }.onChange(of: selection) { tag in pickerChanged(country: tag) }
                }
            }
            .navigationBarTitle("Compare Your Steps")
        }
        
        VStack {
            if(toggle) {
                if(steps != nil) {
                    Text(choice).padding()
                    /*
                     If the selected country's daily step count is less
                     than the user's, then a different message is displayed.
                     */
                    if(different! - steps! < 0) {
                        Text("You walked \(steps!) over the past day. That's more than the selected country's average! Good job!")
                    } else {
                        Text("You walked \(steps!) steps over the past day. You need to walk \(different! - steps!) more steps to reach that country's average.").padding()
                    }
                } else {
                    /*
                     If unable to grab step data from device,
                     you're either running in a simulator or
                     you disabled permissions.
                     */
                    Text("Unable to fetch step data from your device. Are you running this in a simulator?").padding()
                }
            }
            
            
        }.onAppear{
            initializePedometer()
        }
        
    }
    
    /*
     When a selection is made, this function is called
     and it displays the number of steps for the selected
     country onscreen.
     */
    func pickerChanged(country : String) {
        for ea in countryCont.countries {
            if(country == ea.country) {
                choice = "People in \(ea.country) walk an average of \(ea.steps) steps per day."
                toggle = true
                different = ea.steps
            }
        }
    }
}

struct CountryData : Codable, Hashable, Identifiable {
    public var id: Int
    public var country: String
    public var steps: Int
}


class CountryController : ObservableObject {
    @Published var countries = [CountryData]()

    init() {
        getCountry()
    }
    
    /*
     The following uses Alamofire to fetch JSON data.
     The JSON data is a list of countries with their
     associated average steps. The data is stored
     in a dictionary to be displayed in the picker above.
     */
    func getCountry() {
        /* I created a sample JSON file to play with. */
        AF.request("https://www.stickerbru.com/example.json")
        .responseJSON{
            response in
            switch response.result {
            case let .success(value):
                let json = value
                if  (json as? [String : AnyObject]) != nil{
                    if let dictionaryArray = json as? Dictionary<String, AnyObject?> {
                        let jsonArray = dictionaryArray["value"]
                        if let jsonArray = jsonArray as? Array<Dictionary<String, AnyObject?>>{
                            for i in 0..<jsonArray.count{
                                let json = jsonArray[i]
                                if let id = json["id"] as? Int,
                                let countryString = json["location"] as? String,
                                let stepsCount = json["steps"] as? Int{
                                    self.countries.append(CountryData(id: id, country: countryString, steps: stepsCount))
                                }
                            }
                        }
                    }
                }
                /* If unable to fetch file, print error */
            case let .failure(error):
                print(error)
            }

        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
