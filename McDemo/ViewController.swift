//
//  ViewController.swift
//  McDemo
//
//  Created by iMac on 17/10/23.
//

import UIKit
import CoreLocation

enum WeatherType: String {
    case Temperature = "temperature"
    case Cloudy = "cloud"
    case DewPoint = "dewpoint"
    case Humidity = "humidity"
    case Rain = "rain"
    case Visibility = "visibility"
    case Wind = "wind"
    case Pressure = "pressure"
}

class WeatherCell: UITableViewCell {
    
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var desc: UILabel!
}

class ViewController: UIViewController {

    @IBOutlet weak var tbl: UITableView!
    
    @IBOutlet weak var viewTop: UIView!
    @IBOutlet weak var lblCurrentTemp: UILabel!
    @IBOutlet weak var lblCurrentTempStatus: UILabel!
    
    @IBOutlet weak var lblLowTemp: UILabel!
    @IBOutlet weak var lblHighTemp: UILabel!
    
    let locManager = CLLocationManager()

    let types: [WeatherType] = [.Temperature, .Wind, .Humidity, .DewPoint, .Pressure, .Cloudy, .Rain, .Visibility]
    var weatherData: NSDictionary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.checkLocationPermissionStatus()
    }

    func setupUI() {
        
        self.navigationItem.title = "Weather"
        self.setNavRightBarButton()
        
        viewTop.layer.cornerRadius = 16.0
        viewTop.layer.shadowColor = UIColor.lightGray.cgColor
        viewTop.layer.shadowOffset = CGSize(width: 2, height: 2)
        viewTop.layer.shadowOpacity = 1.0
        viewTop.layer.shadowRadius = 4.0
        
        tbl.delegate = self
        tbl.dataSource = self
        tbl.reloadData()
    }
    
    func setNavRightBarButton() {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        btn.setTitle("Search", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        btn.addTarget(self, action: #selector(self.searchBtnPressed), for: .touchUpInside)
        let searchBtn = UIBarButtonItem(customView: btn)
        
        self.navigationItem.rightBarButtonItems = [searchBtn]
    }
    
    @objc func searchBtnPressed() {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "SearchLocationViewController") as! SearchLocationViewController
        nextVC.delegate = self
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
    func fetchWeatherData(latitude: Double?, longitude: Double?, country: String?, city: String?) {
        
        var url: URL?
        if let latitude = latitude, let longitude = longitude {
            
            url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&units=metric&appid=9cf169bfbfc676f30a70e7faa2380b96")

        } else if let country = country, let city = city {
            var countryCode: String = ""
            for (key, value) in arrCountryDetail {
                if key.lowercased() == country.lowercased() {
                    countryCode = arrCountryDetail[key] ?? ""
                    break
                }
            }
            url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(city.lowercased()),\(countryCode)&units=metric&appid=9cf169bfbfc676f30a70e7faa2380b96")
        }
        
        guard let url = url else { return }
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")


        let task = URLSession.shared.dataTask(with: request as URLRequest) {data, response, error in
            
            DispatchQueue.main.async {
                
                if error == nil {
                    let response = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    
                    do {
                        
                        if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as? NSDictionary {
                            print(json)
                            self.weatherData = json
                            self.setWeatherData()
                            self.tbl.reloadData()
                        }
                        
                    } catch {
                        
                    }
                }
            }
        }
        task.resume()
    }
    
    func setWeatherData() {
        if let weatherData = self.weatherData {
            if let main = weatherData["main"] as? NSDictionary {
                if let temp_max = main["temp_max"] as? Double {
                    self.lblHighTemp.text = "\(temp_max)°"
                }
                
                if let temp_min = main["temp_min"] as? Double {
                    self.lblLowTemp.text = "\(temp_min)°"
                }
                
                if let temp = main["temp"] as? Double {
                    self.lblCurrentTemp.text = "\(temp)°"
                }
            }
            
            if let weather = weatherData["weather"] as? NSArray, let firstObj = weather.firstObject as? NSDictionary {
                if let description = firstObj["description"] as? String {
                    self.lblCurrentTempStatus.text = description
                }
            }
        }
    }
}

extension ViewController: SearchDelegate {
    func search(country: String, city: String) {
        self.fetchWeatherData(latitude: nil, longitude: nil, country: country, city: city)
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.checkLocationPermissionStatus()
    }
    
    func checkLocationPermissionStatus() {
        
        locManager.delegate = self
        let locStatus = CLLocationManager.authorizationStatus()
        switch locStatus {
        case .notDetermined:
            locManager.requestWhenInUseAuthorization()
            return
        case .restricted, .denied:
            self.locationPermissionDeniedAction()
        case .authorizedAlways, .authorizedWhenInUse:
            self.getCurrentLocation()
        @unknown default:
            break
        }
    }
    
    func locationPermissionDeniedAction() {
        let alertController = UIAlertController(title: "Location Permission Required", message: "Please enable location permissions in settings.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Settings", style: .default, handler: {(cAlertAction) in
            //Redirect to Settings app
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func getCurrentLocation() {
        guard let currentLocation = locManager.location else {
            return
        }
        let latitude = Double(currentLocation.coordinate.latitude)
        let longitude = Double(currentLocation.coordinate.longitude)
        
        self.fetchWeatherData(latitude: latitude, longitude: longitude, country: nil, city: nil)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
        cell.img.image = UIImage(named: types[indexPath.row].rawValue)
        cell.title.text = types[indexPath.row].rawValue.capitalized
        
        if let weatherData = self.weatherData {
                        
            switch types[indexPath.row] {
            case .Cloudy:
                if let cloud = weatherData["clouds"] as? NSDictionary, let all = cloud["all"] as? Int {
                    cell.desc.text = "\(all) %"
                }
            case .Humidity:
                if let main = weatherData["main"] as? NSDictionary, let humidity = main["humidity"] as? Int {
                    cell.desc.text = "\(humidity) %"
                }
            case .DewPoint:
                if let main = weatherData["main"] as? NSDictionary, let feels_like = main["feels_like"] as? Double {
                    cell.desc.text = "\(feels_like)°"
                }
            case .Pressure:
                if let main = weatherData["main"] as? NSDictionary, let pressure = main["pressure"] as? Int {
                    cell.desc.text = "\(pressure) hPa"
                }
            case .Temperature:
                if let main = weatherData["main"] as? NSDictionary, let temp = main["temp"] as? Double {
                    cell.desc.text = "\(temp)°C"
                }
            case .Visibility:
                if let visibility = weatherData["visibility"] as? Int {
                    cell.desc.text = "\(visibility) Km"
                }
            case .Rain:
                cell.desc.text = "0 %"
            case .Wind:
                if let wind = weatherData["wind"] as? NSDictionary, let speed = wind["speed"] as? Double {
                    cell.desc.text = "\(speed) Kt"
                }
            }
        }

        return cell
    }
}
