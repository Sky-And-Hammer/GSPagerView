//
//  GSPagerViewTransformer.swift
//  GSPagerView
//
//  Created by 孟钰丰 on 2017/12/21.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

/// 切换动画
///
/// - crossFading: <#crossFading description#>
/// - zoomOut: <#zoomOut description#>
/// - depth: <#depth description#>
/// - overlap: <#overlap description#>
/// - linear: <#linear description#>
/// - coverFlow: <#coverFlow description#>
/// - ferrisWheel: <#ferrisWheel description#>
/// - invertedFerrisWheel: <#invertedFerrisWheel description#>
/// - cubic: <#cubic description#>
public enum GSPagerViewTransformerType: Int {
    case crossFading
    case zoomOut
    case depth
    case overlap
    case linear
    case coverFlow
    case ferrisWheel
    case invertedFerrisWheel
    case cubic
}

// MARK: GSPagerViewTransformer

open class GSPagerViewTransformer {
    
    weak var pagerView: GSPagerView?
    
    var type: GSPagerViewTransformerType
    var minScale: CGFloat = 0.65
    var minAlpha: CGFloat = 0.6
    
    init(type: GSPagerViewTransformerType) {
        self.type = type
        switch type {
        case .zoomOut: self.minScale = 0.85
        case .depth: self.minScale = 0.5
        default: break
        }
    }
    
    // Apply transform to attributes - zIndex: Int, frame: CGRect, alpha: CGFloat, transform: CGAffineTransform or transform3D: CATransform3D.
    func apply(to attributes: GSPagerViewLayoutAttributes) {
        guard let pagerView = pagerView else { return }
        let position = attributes.position
        let direction = pagerView.scrollDirection
        let itemSpacing = (direction == .horizontal ? attributes.bounds.width : attributes.bounds.height) + proposedInterItemSpacing()
        switch type {
        case .crossFading:
            let value = abs(position) < 1
            attributes.do {
                $0.alpha = value ? 1 - abs(position) : 0
                $0.zIndex = value ? 1 : Int.min
                switch direction {
                case .horizontal: $0.transform = CGAffineTransform.init(translationX: -itemSpacing * position, y: 0)
                case .vertical: $0.transform = CGAffineTransform.init(translationX: 0, y: -itemSpacing * position)
                }
            }
        case .zoomOut:
            var alpha: CGFloat = 0
            var transform = CGAffineTransform.identity
            switch position {
            case -1 ... 1:
                let scaleFactor = max(self.minScale, 1 - abs(position))
                transform.a = scaleFactor
                transform.d = scaleFactor
                switch direction {
                case .horizontal:
                    let vertMargin = attributes.bounds.height * (1 - scaleFactor) / 2;
                    let horzMargin = itemSpacing * (1 - scaleFactor) / 2;
                    transform.tx = position < 0 ? (horzMargin - vertMargin*2) : (-horzMargin + vertMargin*2)
                case .vertical:
                    let horzMargin = attributes.bounds.width * (1 - scaleFactor) / 2;
                    let vertMargin = itemSpacing * (1 - scaleFactor) / 2;
                    transform.ty = position < 0 ? (vertMargin - horzMargin*2) : (-vertMargin + horzMargin*2)
                }
                
                alpha = minAlpha + (scaleFactor - minScale) / (1 - minScale) * (1 - minAlpha)
            default: break
            }
            
            attributes.do {
                $0.alpha = alpha
                $0.transform = transform
            }
        case .depth:
            var transform = CGAffineTransform.identity
            var zIndex = 0
            var alpha: CGFloat = 0.0
            switch position {
            case -1 ... 0:  // [-1,0]
                alpha = 1
                transform.tx = 0
                transform.a = 1
                transform.d = 1
                zIndex = 1
            case 0 ..< 1: // (0,1)
                alpha = CGFloat(1.0) - position
                // Counteract the default slide transition
                switch direction {
                case .horizontal:
                    transform.tx = itemSpacing * -position
                case .vertical:
                    transform.ty = itemSpacing * -position
                }
                // Scale the page down (between minimumScale and 1)
                let scaleFactor = minAlpha + (1.0 - minAlpha) * (1.0 - abs(position));
                transform.a = scaleFactor
                transform.d = scaleFactor
                zIndex = 0
            default:
                break
            }
            
            attributes.do {
                $0.alpha = alpha
                $0.transform = transform
                $0.zIndex = zIndex
            }
        case .overlap, .linear:
            guard direction == .horizontal else { return }
            attributes.do {
                $0.alpha = (minAlpha + (1 - abs(position)) * (1 - minAlpha))
                $0.zIndex = Int((1-abs(position)) * 10)
                let scale = max(1 - (1 - minScale) * abs(position), minScale)
                $0.transform = CGAffineTransform.init(scaleX: scale, y: scale)
            }
        case .coverFlow:
            guard direction == .horizontal else { return }
            let position = min(max(-position,-1) ,1)
            let rotation = sin(position * (.pi) * 0.5) * (.pi) * 0.25 * 1.5
            let translationZ = -itemSpacing * 0.5 * abs(position)
            var transform3D = CATransform3DIdentity
            transform3D.m34 = -0.002
            transform3D = CATransform3DRotate(transform3D, rotation, 0, 1, 0)
            transform3D = CATransform3DTranslate(transform3D, 0, 0, translationZ)
            attributes.zIndex = 100 - Int(abs(position))
            attributes.transform3D = transform3D
        case .ferrisWheel, .invertedFerrisWheel:
            guard direction == .horizontal else { return }
            var transform = CGAffineTransform.identity
            var zIndex = 0
            let alpha: CGFloat = abs(position) < 0.5 ? 1 : self.minAlpha
            switch position {
            case -5 ... 5:
                let itemSpacing = attributes.bounds.width + proposedInterItemSpacing()
                let count: CGFloat = 14
                let circle: CGFloat = .pi * 2.0
                let radius = itemSpacing * count / circle
                let ty = radius * (type == .ferrisWheel ? 1 : -1)
                let theta = circle / count
                let rotation = position * theta * (type == .ferrisWheel ? 1 : -1)
                transform = transform.translatedBy(x: -position*itemSpacing, y: ty)
                transform = transform.rotated(by: rotation)
                transform = transform.translatedBy(x: 0, y: -ty)
                zIndex = Int((4.0-abs(position)*10))
            default: break
            }
            attributes.do {
                $0.alpha = alpha
                $0.transform = transform
                $0.zIndex = zIndex
            }
        case .cubic:
            var transform3D = CATransform3DIdentity
            var zIndex = 0
            var alpha: CGFloat = 0.0
            switch position {
            case -1 ..< 1:
                alpha = 1
                zIndex = Int((1 - position) * CGFloat(10))
                let directionValue: CGFloat = position < 0 ? 1 : -1
                let theta = position * .pi * 0.5 * (direction == .horizontal ? 1 : -1)
                let radius = direction == .horizontal ? attributes.bounds.width : attributes.bounds.height
                
                transform3D.m34 = -0.002
                switch direction {
                case .horizontal:
                    attributes.center.x += directionValue * radius * 0.5
                    transform3D = CATransform3DRotate(transform3D, theta, 0, 1, 0)
                    transform3D = CATransform3DTranslate(transform3D,-directionValue * radius*0.5, 0, 0)
                case .vertical:
                    attributes.center.y += directionValue * radius * 0.5
                    transform3D = CATransform3DRotate(transform3D, theta, 1, 0, 0)
                    transform3D = CATransform3DTranslate(transform3D,0, -directionValue * radius*0.5, 0)
                }
            default: break
            }
            attributes.do {
                $0.alpha = alpha
                $0.transform3D = transform3D
                $0.zIndex = zIndex
            }
        }
    }
    
    // An interitem spacing proposed by transformer class. This will override the default interitemSpacing provided by the pager view.
    func proposedInterItemSpacing() -> CGFloat {
        guard let pagerView = pagerView else { return 0}
        
        let direction = pagerView.scrollDirection
        switch type {
        case .overlap: return direction == .horizontal ? (pagerView.itemSize.width * -minScale * 0.6) : 0
        case .linear: return direction == .horizontal ? (pagerView.itemSize.width * -minScale * 0.2) : 0
        case .coverFlow: return direction == .horizontal ? (-pagerView.itemSize.width * sin(.pi * 0.25 * 0.25 * 3.0)) : 0
        case .ferrisWheel, .invertedFerrisWheel: return direction == .horizontal ? (-pagerView.itemSize.width * 0.15) : 0
        case .cubic: return 0
        default: return pagerView.interitemSpacing
        }
    }
}
