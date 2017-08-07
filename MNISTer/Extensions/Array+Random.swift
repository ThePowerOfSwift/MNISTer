//
//  Array+Random.swift
//  MNISTer
//
//  Created by William McGinty on 8/5/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import Foundation

extension Array {
    var random: Array.Element {
        let random = Int(arc4random_uniform(UInt32(count)))
        return self[random]
    }
}
