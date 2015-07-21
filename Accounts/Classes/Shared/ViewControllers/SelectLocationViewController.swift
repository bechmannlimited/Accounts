//
//  SelectLocationViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
//import GoogleMaps
import MapKit
import ABToolKit

class SelectLocationViewController: UIViewController {

    var mapView = MKMapView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupMapView()
    }

    func setupMapView() {
    
        //constraints
        mapView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(mapView)
        mapView.fillSuperView(UIEdgeInsetsZero)
        
        //let searchBar = UISearchBar()
    }
}
