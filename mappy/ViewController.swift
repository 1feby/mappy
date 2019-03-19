//
//  ViewController.swift
//  mappy
//
//  Created by Abanoub Ghaly on 3/19/19.
//  Copyright © 2019 Abanoub Ghaly. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation
class ViewController: UIViewController {

    @IBOutlet weak var directionsLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
   
    
    let locationManager=CLLocationManager()
    var currentCoordinate : CLLocationCoordinate2D!
    var steps = [MKRoute.Step]()
    let speechSyn = AVSpeechSynthesizer()
    var stepCounter = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.requestAlwaysAuthorization()
        locationManager.delegate=self
        locationManager.desiredAccuracy=kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        
        
    }

    func getDirection (to destination: MKMapItem){
        
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        directionsRequest.transportType = .automobile
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, _) in
            guard let response = response else { return }
            guard let primaryRoute = response.routes.first else { return }
            
            self.mapView.addOverlay(primaryRoute.polyline)
           
            self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0)  })
            
            self.steps = primaryRoute.steps
            
            for i in 0 ..< primaryRoute.steps.count {
                let step = primaryRoute.steps[i]
                print(step.distance)
                print(step.instructions)
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 5, identifier: "\(i)")
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.addOverlay(circle)
            }
        let initialMessage = "in \(self.steps[1].distance) meters,\(self.steps[1].instructions) ,then in \(self.steps[2].distance) meters, \(self.steps[2].instructions) ."
            self.directionsLabel.text = initialMessage
            let speechUtt = AVSpeechUtterance(string: initialMessage)
            self.speechSyn.speak(speechUtt)
            self.stepCounter += 1
        }
        
        
        
    }

}

extension ViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     manager.stopUpdatingLocation()
        guard let currentLocation=locations.first else { return }
        currentCoordinate = currentLocation.coordinate
        mapView.userTrackingMode = .followWithHeading
        
        
        
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("entered")
        stepCounter += 1
        if stepCounter < steps.count {
            let currentSteps = steps[stepCounter]
            let message = "in \(currentSteps.distance) meters,\(currentSteps.instructions) ,then in \(currentSteps.distance) meters, \(currentSteps.instructions) ."
            directionsLabel.text = message
            let speechUtt = AVSpeechUtterance(string: message)
            self.speechSyn.speak(speechUtt)
        
        }else {
            let message = "Arrived at destination"
            directionsLabel.text = message
            let speechUtt = AVSpeechUtterance(string: message)
            self.speechSyn.speak(speechUtt)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0) })
        }
    }
    
}
extension ViewController : UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        let localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        let region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        localSearchRequest.region = region
        let localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (response,  _) in
            guard let response = response else { return }
            print(response.mapItems)
                guard let firstMapItem = response.mapItems.first else { return }
            self.getDirection(to: firstMapItem)

        }
        
    }
}
extension ViewController : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.lineWidth = 10
            return renderer
        }
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .yellow
            renderer.fillColor = .black
            renderer.alpha = 0.5
            return renderer
        }
        
        
        return MKOverlayRenderer()
    }
}
