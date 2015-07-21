//
//  DateFormat.swift
//  objectmapperTest
//
//  Created by Alex Bechmann on 29/04/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

public enum DateFormat: String {
    
    case Date = "dd/MM/yyyy"
    case DateTime = "dd/MM/yyyy HH:mm"
    case DateTimeWithSeconds = "dd/MM/yyyy HH:mm:ss"
    //case ISO8601 = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    case ISO8601 = "yyyy-MM-dd'T'HH:mm:ss"
    //case ISO8601 = "yyyy-MM-dd'T'HH:mm:ss"
}
