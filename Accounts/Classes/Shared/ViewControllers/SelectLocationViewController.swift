//
//  SelectLocationViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import GoogleMaps
import MapKit
import ABToolKit

class SelectLocationViewController: UIViewController {

    var tableView = UITableView()
    var matches = [AnyObject]()
    var searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var camera = GMSCameraPosition.cameraWithLatitude(-33.86,
            longitude: 151.20, zoom: 6)
        var mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        self.view = mapView
        
        var marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(-33.86, 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = mapView
    }
    
    func setupSearchController() {
        
        let searchBar = searchController.searchBar
//        
//        searchController.delegate = self
//        searchBar.delegate = self
        
        tableView.tableHeaderView = searchBar
        searchBar.sizeToFit()
        
        searchController.dimsBackgroundDuringPresentation = false
    }
}
