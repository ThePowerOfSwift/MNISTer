//
//  IllustratorView.swift
//  MNISTer
//
//  Created by William McGinty on 8/5/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit

public class IllustratorView: UIView {
    
    //MARK: Properties
    private lazy var mainImageView: UIImageView = UIImageView(frame: .zero)
    private lazy var temporaryImageView: UIImageView = UIImageView(frame: .zero)
    
    @IBInspectable public var pencilWidth: CGFloat = 10
    
    private var isSwiping = false
    private var lastPoint: CGPoint?
    
    //MARK: Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }
    
    private func initializeView() {
        addSubview(mainImageView)
        mainImageView.frame = bounds
        
        addSubview(temporaryImageView)
        temporaryImageView.frame = bounds
        
        mainImageView.backgroundColor = .white
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        mainImageView.frame = bounds
        temporaryImageView.frame = bounds
    }
}

//MARK: Interface
public extension IllustratorView {
    
    var current: UIImage? {
        return mainImageView.image
    }
    
    func resetCanvas() {
        mainImageView.image = nil
        temporaryImageView.image = nil
    }
}

//MARK: Touch Handling
public extension IllustratorView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        isSwiping = false
        lastPoint = touches.first?.location(in: temporaryImageView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        isSwiping = true
        if let touch = touches.first, let last = lastPoint {
            let current = touch.location(in: temporaryImageView)
            
            overlayLine(from: last, to: current, on: temporaryImageView)
            self.lastPoint = current
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if !isSwiping, let last = lastPoint {
            overlayLine(from: last, to: last, on: temporaryImageView)
        }

        mainImageView.image = compositedContents(of: mainImageView, and: temporaryImageView)
        temporaryImageView.image = nil
    }
}

//MARK: Helper
fileprivate extension IllustratorView {
    
    func overlayLine(from source: CGPoint, to destination: CGPoint, on imageView: UIImageView) {
        UIGraphicsBeginImageContext(imageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        defer { UIGraphicsEndImageContext() }
        
        imageView.image?.draw(in: CGRect(x: 0, y: 0, width: imageView.bounds.width, height: imageView.bounds.height))
        
        context?.move(to: source)
        context?.addLine(to: destination)
        
        context?.setLineCap(.round)
        context?.setLineWidth(pencilWidth)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setBlendMode(.normal)
        context?.strokePath()
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func compositedContents(of imageView: UIImageView, and otherImageView: UIImageView) -> UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: imageView.bounds.size))
        
        imageView.image?.draw(in: CGRect(origin: .zero, size: imageView.bounds.size), blendMode: .normal, alpha: 1)
        otherImageView.image?.draw(in: CGRect(origin: .zero, size: imageView.bounds.size), blendMode: .normal, alpha: 1)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
