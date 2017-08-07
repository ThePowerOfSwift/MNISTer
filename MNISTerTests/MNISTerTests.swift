//
//  MNISTerTests.swift
//  MNISTerTests
//
//  Created by William McGinty on 8/2/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import XCTest
@testable import MNISTer

class MNISTerTests: XCTestCase {
    
    lazy var glyphExtractor: GlyphExtractor = {
        let baseImage = UIImage(named: "WWDC.jpg", in: Bundle(for: MNISTerTests.self), compatibleWith: nil)!
        return GlyphExtractor(inputImage: CIImage(image: baseImage)!)
    }()
    
    func testOrientation() {
        let y = glyphExtractor.inputImage
        print(glyphExtractor)
    }
}
