//
//  OneRubberPageControl.swift
//  OneRubberPageControl
//
//  Created by OneLei on 2018/1/20.
//  Copyright © 2018年 OneLei. All rights reserved.
//

import UIKit

// MARK: - MoveDorection
// 运动方向
private enum OneMoveDirection {
    case left
    case right
    func isLeft() -> Bool {
        switch self {
        case .left:
            return true
        case .right:
            return false
        }
    }
}

public struct OneRubberPageControlConfig {
    public var smallBubbleSize: CGFloat         // 小球尺寸
    public var mainBubbleSize: CGFloat          // 大球尺寸
    public var bubbleXOffsetSpace: CGFloat      // 小球间距
    public var bubbleYOffsetSpace: CGFloat      // 小球纵向间距
    public var smallBubbleMoveRadius: CGFloat { return smallBubbleSize + bubbleXOffsetSpace}    // 小球运动半径
    public var animationDuration: CFTimeInterval     // 动画时长
    public var backgroundColor: UIColor         // 横条背景颜色
    public var smallBubbleColor: UIColor        // 小球颜色
    public var mainBubbleColor: UIColor         // 大球颜色
    
    public init(smallBubbleSize: CGFloat = 16,
         mainBubbleSize: CGFloat = 40,
         bubbleXOffsetSpace: CGFloat = 12,
         bubbleYOffsetSpace: CGFloat = 8,
         animationDuration: CFTimeInterval = 0.2,
         backgroundColor: UIColor = UIColor(red:0.741,  green:0.945,  blue:0.757, alpha:1),
         smallBubbleColor: UIColor = UIColor(red:1,  green:0.829,  blue:0, alpha:1),
         mainBubbleColor: UIColor = UIColor(red:1,  green:0.668,  blue:0.474, alpha:1)) {
        self.smallBubbleSize = smallBubbleSize
        self.mainBubbleSize = mainBubbleSize
        self.bubbleXOffsetSpace = bubbleXOffsetSpace
        self.bubbleYOffsetSpace = bubbleYOffsetSpace
        self.animationDuration = animationDuration
        self.backgroundColor = backgroundColor
        self.smallBubbleColor = smallBubbleColor
        self.mainBubbleColor = mainBubbleColor
    }
}

open class OneRubberPageControl: UIControl {
    
    // 页数
    open var numberOfpage : Int  = 5 {
        didSet{
            if oldValue != numberOfpage{
                resetRubberIndicator()
            }
        }
    }
    
    // 当前 Index
    open var currentIndex  = 0 {
        didSet {
            changeToIndex(currentIndex)
        }
    }
    
    // 样式
    open var styleConfig : OneRubberPageControlConfig {
        didSet {
            resetRubberIndicator()
        }
    }
    
    // 闭包事件
    open var valueChange:((Int) -> Void)?
    
    // 手势
    private var indexTap: UITapGestureRecognizer?
    
    // 大球缩放比例
    private let bubbleScale  : CGFloat  = 1/3.0
    
    // 图层
    private var smallBubbles = [OneBubbleelCell]()
    private var backgroundLayer = CAShapeLayer.init()
    private var mainBubble = CAShapeLayer.init()
    private var backLineLayer = CAShapeLayer.init()
    
    // 存储计算用的
    private var xPointbegin: CGFloat = 0
    private var xPointEnd: CGFloat = 0
    private var yPointbegin: CGFloat = 0
    private var yPointEnd: CGFloat = 0
    
    public init(frame: CGRect, count: Int, config: OneRubberPageControlConfig = OneRubberPageControlConfig()) {
        numberOfpage = count
        styleConfig = config
        super.init(frame: frame)
        initView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        styleConfig = OneRubberPageControlConfig.init()
        super.init(coder: aDecoder)
        initView()
    }
    
    private func initView() {
        
        let y = (bounds.height - (styleConfig.smallBubbleSize + 2 * styleConfig.bubbleYOffsetSpace)) / 2
        let w = CGFloat(numberOfpage) * styleConfig.smallBubbleSize + CGFloat(numberOfpage + 1) * styleConfig.bubbleXOffsetSpace
        let h = styleConfig.smallBubbleSize + 2 * styleConfig.bubbleYOffsetSpace
        let x = (bounds.width - w) / 2
        
        let lineFrame = CGRect.init(x: x, y: y, width: w, height: h)
        let backBubbleFrame = CGRect.init(x: x, y: y - (styleConfig.mainBubbleSize - h) / 2, width: styleConfig.mainBubbleSize, height: styleConfig.mainBubbleSize)
        let bigBubbleFrame = backBubbleFrame.insetBy(dx: styleConfig.bubbleYOffsetSpace, dy: styleConfig.bubbleYOffsetSpace)
        
        xPointbegin = x
        xPointEnd = x + w
        yPointbegin = y
        yPointEnd = y + h
        
        // 背景的横线
        backLineLayer.path = UIBezierPath.init(roundedRect: lineFrame, cornerRadius: 15).cgPath
        backLineLayer.fillColor = styleConfig.backgroundColor.cgColor
        backLineLayer.frame = bounds
        layer.addSublayer(backLineLayer)
        
        // 大球背景的圈
        backgroundLayer.path = UIBezierPath.init(ovalIn: CGRect.init(origin: CGPoint.zero, size:backBubbleFrame.size)).cgPath
        backgroundLayer.frame = backBubbleFrame
        backgroundLayer.fillColor = styleConfig.backgroundColor.cgColor
        backgroundLayer.zPosition = -1
        layer.addSublayer(backgroundLayer)
        
        // 大球
        mainBubble.path = UIBezierPath.init(ovalIn: CGRect.init(origin: CGPoint.zero, size: bigBubbleFrame.size)).cgPath
        mainBubble.frame = bigBubbleFrame
        mainBubble.fillColor = styleConfig.mainBubbleColor.cgColor
        mainBubble.zPosition = 100
        layer.addSublayer(mainBubble)
        
        // 小球
        for i in 0..<(numberOfpage - 1) {
            let smallBubble = OneBubbleelCell.init(style: styleConfig)
            smallBubble.frame = CGRect.init(x: x + styleConfig.bubbleXOffsetSpace + CGFloat(i + 1) * (styleConfig.bubbleXOffsetSpace + styleConfig.smallBubbleSize), y: y + styleConfig.bubbleYOffsetSpace, width: styleConfig.smallBubbleSize, height: styleConfig.smallBubbleSize)
            smallBubbles.append(smallBubble)
            layer.addSublayer(smallBubble)
            smallBubble.zPosition = 1
        }
        
        if indexTap == nil {
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapValueChanged(_:)))
            addGestureRecognizer(tap)
            indexTap = tap
        }
        
    }
    
    open func resetRubberIndicator() {
        changeToIndex(0)
        smallBubbles.forEach { $0.removeFromSuperlayer() }
        smallBubbles.removeAll()
        initView()
    }
    
    // 手势事件
    @objc private func tapValueChanged(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self)
        if point.y > yPointbegin && point.y < yPointEnd && point.x > xPointbegin && point.x < xPointEnd {
            let index = Int(point.x - xPointbegin) / Int(styleConfig.smallBubbleMoveRadius)
            changeToIndex(index)
        }
    }
    
    private func changeToIndex(_ index: Int) {
        var indexValue = index
        if indexValue >= numberOfpage {
            indexValue = numberOfpage - 1
        }
        if indexValue < 0 {
            indexValue = 0
        }
        if indexValue == currentIndex {
            return
        }
        
        let direction = currentIndex > indexValue ? OneMoveDirection.right : OneMoveDirection.left
        // 有问题
        let range = (currentIndex < indexValue) ? (currentIndex+1)...indexValue : indexValue...(currentIndex-1)
        // 小球动画
        for index in range {
            let smallBubbleIndex = direction.isLeft() ? (index - 1) : index
            let smallBubble = smallBubbles[smallBubbleIndex]
            smallBubble.positionChange(direction)
        }
    
        currentIndex = indexValue
        
        // 大球缩放动画
        let bubbleTransformAnim = CAKeyframeAnimation.init(keyPath: "transform")
        
        bubbleTransformAnim.values   = [NSValue(caTransform3D: CATransform3DIdentity),
                                        NSValue(caTransform3D: CATransform3DMakeScale(bubbleScale, bubbleScale, 1)),
                                        NSValue(caTransform3D: CATransform3DIdentity)]
        bubbleTransformAnim.keyTimes = [0, 0.5, 1]
        bubbleTransformAnim.duration = styleConfig.animationDuration
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(styleConfig.animationDuration)
        let x = xPointbegin + styleConfig.smallBubbleMoveRadius * CGFloat(currentIndex) + styleConfig.mainBubbleSize/2
        mainBubble.position.x = x
        backgroundLayer.position.x = x
        CATransaction.commit()

        mainBubble.add(bubbleTransformAnim, forKey: "Scale")
        
        sendActions(for: UIControlEvents.valueChanged)
        
        valueChange?(currentIndex)
    }
    
}

// MARK: - Small Bubble
private class OneBubbleelCell: CAShapeLayer, CAAnimationDelegate {
    
    var bubbleLayer = CAShapeLayer()
    let bubbleScale : CGFloat  = 0.5
    var lastDirection : OneMoveDirection!
    var styleConfig: OneRubberPageControlConfig
    var cachePosition = CGPoint.zero
    
    override init(layer: Any) {
        styleConfig = OneRubberPageControlConfig.init()
        super.init(layer: layer)
        setupLayer()
    }
    
    internal init(style: OneRubberPageControlConfig) {
        self.styleConfig = style
        super.init()
        setupLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        styleConfig = OneRubberPageControlConfig.init()
        super.init(coder: aDecoder)
        setupLayer()
    }
    
    func setupLayer() {
        frame = CGRect.init(x: 0, y: 0, width: styleConfig.smallBubbleSize, height: styleConfig.smallBubbleSize)
        
        bubbleLayer.path = UIBezierPath.init(ovalIn: bounds).cgPath
        bubbleLayer.fillColor = styleConfig.smallBubbleColor.cgColor
        bubbleLayer.strokeColor = styleConfig.backgroundColor.cgColor
        bubbleLayer.lineWidth = styleConfig.bubbleXOffsetSpace / 8
        addSublayer(bubbleLayer)
    }
    
    // 旋转跳跃我闭上眼
    func positionChange(_ direction: OneMoveDirection) {
        let movePath = UIBezierPath.init()
        var center = CGPoint.zero
        let startAngle: CGFloat = direction.isLeft() ? 0 : CGFloat.pi
        let endAngle: CGFloat = direction.isLeft() ? CGFloat.pi : 0
        center.x += (styleConfig.bubbleXOffsetSpace + styleConfig.smallBubbleSize) / 2 * (direction.isLeft() ? -1 : 1)
        lastDirection = direction
        
        movePath.addArc(withCenter: center, radius: (styleConfig.bubbleXOffsetSpace + styleConfig.smallBubbleSize)/2, startAngle: startAngle, endAngle: endAngle, clockwise: direction.isLeft())
        
        let positionAnimation = CAKeyframeAnimation.init(keyPath: "position")
        positionAnimation.duration = styleConfig.animationDuration
        positionAnimation.beginTime = CACurrentMediaTime()
        positionAnimation.isAdditive = true
        positionAnimation.calculationMode = kCAAnimationPaced
        positionAnimation.rotationMode = kCAAnimationRotateAuto
        positionAnimation.path = movePath.cgPath
        positionAnimation.fillMode = kCAFillModeForwards
        positionAnimation.isRemovedOnCompletion = false
        positionAnimation.delegate = self
        cachePosition = position
        
        let bubbleTransformAnim      = CAKeyframeAnimation(keyPath: "transform")
        bubbleTransformAnim.values   = [NSValue(caTransform3D: CATransform3DIdentity),
                                        NSValue(caTransform3D: CATransform3DMakeScale(1, bubbleScale, 1)),
                                        NSValue(caTransform3D: CATransform3DIdentity)]
        bubbleTransformAnim.keyTimes = [0, 0.5, 1]
        bubbleTransformAnim.duration = duration
        bubbleTransformAnim.beginTime = beginTime
        
        
        bubbleLayer.add(bubbleTransformAnim, forKey: "Scale")
        add(positionAnimation, forKey: "Position")
        
        
        let bubbleShakeAnim = CAKeyframeAnimation(keyPath: "position")
        bubbleShakeAnim.beginTime = beginTime + duration + 0.05;
        bubbleShakeAnim.duration = 0.02
        bubbleShakeAnim.values = [NSValue(cgPoint: CGPoint(x: 0, y: 0)),
                                  NSValue(cgPoint: CGPoint(x: 0, y: 3)),
                                  NSValue(cgPoint: CGPoint(x: 0, y: -3)),
                                  NSValue(cgPoint: CGPoint(x: 0, y: 0)), ]
        bubbleShakeAnim.repeatCount = 6
        bubbleShakeAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        bubbleLayer.add(bubbleShakeAnim, forKey: "Shake")
        
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let animate = anim as? CAKeyframeAnimation {
            if animate.keyPath == "position" {
                removeAnimation(forKey: "Position")
                CATransaction.begin()
                
                CATransaction.setAnimationDuration(0)
                CATransaction.setDisableActions(true)
                var point = cachePosition
                point.x += (styleConfig.smallBubbleSize + styleConfig.bubbleXOffsetSpace) * CGFloat(lastDirection.isLeft() ? -1 : 1)
                position = point
                opacity = 1
                CATransaction.commit()
            }
        }
    }
}
