//
//  ViewController.swift
//  Test technique
//
//  Created by Emilio Del Castillo on 11/03/2021.
//

import UIKit
import MapKit

protocol MainViewDelegate: AnyObject {
    func loadDataToMapView()
}

class MainViewController: UIViewController, MainViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var countryPicker: UIPickerView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    /**
    Timer for the country picker
     */
    internal var timer: Timer!
    
    internal var currentCountryCode: String? {
        didSet {
            loadDataToMapView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        countryPicker.delegate = self
        countryPicker.dataSource = self
        
        // Initial setup
        let france = CLLocationCoordinate2D(latitude: 46.2276,longitude: 2.2137)
        let currentRegion = MKCoordinateRegion(center: france,
                                      latitudinalMeters: 1_000_000,
                                      longitudinalMeters: 1_000_000)
        
        mapView.setRegion(currentRegion, animated: true)
        
        loadCountries()
        loadParameters()
        
    }
    
    // MARK: - Load data
    private func loadParameters() {
        AppData.shared.loadParameters { (error) in
            if error != nil {
                
                // Notify the user
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Unable to load the parameters",
                                                  message: nil,
                                                  preferredStyle: .alert)
                    
                    // Not very sure about this...
                    alert.addAction(UIAlertAction(title: "Try again",
                                                  style: .default,
                                                  handler: { (alert) in
                                                    self.loadParameters()
                                                  }))
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                
            }
        }
    }
    
    private func loadCountries() {
        AppData.shared.loadCountries { (error) in
            if error == nil {
                self.currentCountryCode = AppData.shared.getCountryCode(countryName: "France")
                
                DispatchQueue.main.async {
                    self.countryPicker.reloadAllComponents()
                    let row = AppData.shared.countries?.firstIndex { (country) -> Bool in
                        country.name == "France"
                    }
                    self.countryPicker.selectRow(row ?? 0, inComponent: 0, animated: true)
                }
                
            } else {
                
                // Notify the user
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Unable to load the countries",
                                                  message: "We were unable to load the countries.",
                                                  preferredStyle: .alert)
                    
                    // Not very sure about this...
                    alert.addAction(UIAlertAction(title: "Try again",
                                                  style: .default,
                                                  handler: { (alert) in
                                                    self.loadCountries()
                                                  }))
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
            }
        }
    }

    /**
        Puts the markers on the map view, if a country code is set
     */
    internal func loadDataToMapView() {
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
            
        mapView.removeAnnotations(mapView.annotations)
        
        AppData.shared.getData(for: currentCountryCode!) { error in
            if error != nil {
                var errorMessage: String!
                
                if let test = error as? ResultError {
                    
                    switch test {
                    case .negativeCount:
                        errorMessage = "Negative amount found."
                    case .noResult:
                        errorMessage = "No results."
                    case .unknownError:
                        errorMessage = "Unknown error."
                    }
                    
                } else {
                    errorMessage = error?.localizedDescription
                }
                
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    let alert = UIAlertController(title: errorMessage, message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
                
            } else {
                self.createMarkers {
                    // The only way to make the annotations appear
                    DispatchQueue.main.async {
                        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                        self.spinner.stopAnimating()
                    }
                }
                
            }
        }
        
    }
    
    internal func createMarkers(completion: @escaping () -> Void) {

        //FIXME: This needs to be thought in order to avoid duplicates 🤔
        
        // This operation can be expensive
        DispatchQueue.global(qos: .userInteractive).async {
            for loc in AppData.shared.locations {
                if let lat = loc.coordinates?.latitude, let lon = loc.coordinates?.longitude {
                    
                    let annotationLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let annotation = LocationMark(coordinate: annotationLocation,
                                                  title: loc.city.safelyUnwrappedValue,
                                                  subtitle: loc.location,
                                                  ID: loc.locationId!)
                    
                    self.mapView.addAnnotation(annotation)
                    
                }
            }
            completion()
        }
    }
}


