//
//  GSPagerViewLayout.swift
//  GSPagerView
//
//  Created by 孟钰丰 on 2017/12/21.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import GSStability
import GSFoundation

class GSPagerViewLayoutAttributes: UICollectionViewLayoutAttributes {
    
    open var position: CGFloat = 0
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? GSPagerViewLayoutAttributes else { return false }
        return super.isEqual(object) && (self.position == object.position)
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        return (super.copy(with: zone) as? GSPagerViewLayoutAttributes ?? GSPagerViewLayoutAttributes.init()).then {
            $0.position = self.position
        }
    }
}

class GSPagerViewLayout: UICollectionViewLayout {
    
    override var collectionViewContentSize: CGSize { return contentSize }
    
    internal var contentSize = CGSize.zero
    internal var leadingSpacing: CGFloat = 0
    internal var itemSpacing: CGFloat = 0
    internal var needsReprepare = true
    internal var direction = GSPagerViewDirection.horizontal
    
    open override class var layoutAttributesClass: AnyClass { return GSPagerViewLayoutAttributes.self }
    
    fileprivate var pagerView: GSPagerView? { return collectionView?.superview?.superview as? GSPagerView }
    fileprivate var isInfinite = true
    fileprivate var collectionViewSize = CGSize.zero
    fileprivate var numberOfSections = 1
    fileprivate var numberOfItems = 0
    fileprivate var actualInterItemSpacing: CGFloat = 0
    fileprivate var actualItemSize = CGSize.zero
    
    override init() {
        super.init()
        NotificationCenter.default.gs.addObserver(self, name: .UIDeviceOrientationDidChange, object: nil) { (target, _) in
            if target.pagerView?.itemSize == .zero { target.adjustCollectionViewBounds() }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.gs.addObserver(self, name: .UIDeviceOrientationDidChange, object: nil) { (target, _) in
            if target.pagerView?.itemSize == .zero { target.adjustCollectionViewBounds() }
        }
    }
    
    override func prepare() {
        guard let collectionView = collectionView, let pagerView = pagerView else { return }
        guard needsReprepare || collectionViewSize != collectionView.frame.size else { return }
        
        needsReprepare = false
        collectionViewSize = collectionView.frame.size
        numberOfSections = pagerView.numberOfSections(in: collectionView)
        numberOfItems = pagerView.collectionView(collectionView, numberOfItemsInSection: 0)
        actualItemSize = {
            var size = pagerView.itemSize
            if size == .zero { size = collectionView.frame.size }
            return size
        }()
        actualInterItemSpacing = pagerView.transformer?.proposedInterItemSpacing() ?? pagerView.interitemSpacing
        direction = pagerView.scrollDirection
        leadingSpacing = direction == .horizontal ? (collectionView.frame.width - actualItemSize.width) / 2 : (collectionView.frame.height - actualItemSize.height) / 2
        itemSpacing = direction == .horizontal ? actualItemSize.width : actualItemSize.height + actualInterItemSpacing
        contentSize = {
            let allItems = numberOfItems * numberOfSections
            switch direction {
            case .horizontal:
                var width = leadingSpacing * 2
                width += CGFloat(allItems - 1) * actualInterItemSpacing
                width += CGFloat(allItems) * actualItemSize.width
                return CGSize.init(width: width, height: collectionView.frame.height)
            case .vertical:
                var height = leadingSpacing * 2
                height += CGFloat(allItems - 1) * actualInterItemSpacing
                height += CGFloat(allItems) * actualItemSize.height
                return CGSize.init(width: collectionView.frame.width, height: height)
            }
        }()
        
        adjustCollectionViewBounds()
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { return true }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard itemSpacing > 0, !rect.isEmpty else { return [] }
        let rect = rect.intersection(CGRect.init(origin: CGPoint.zero, size: contentSize))
        guard !rect.isEmpty else { return [] }
        
        let itemsBefore = direction == .horizontal ? max(Int((rect.minX - leadingSpacing) / itemSpacing),0) : max(Int((rect.minY - leadingSpacing) / itemSpacing),0)
        let startPosistion = leadingSpacing + CGFloat(itemsBefore) * itemSpacing
        let startIndex = itemsBefore
        var itemIndex = startIndex
        var origin = startPosistion
        let maxPosition = direction == .horizontal ? min(rect.maxX, contentSize.width - actualItemSize.width - leadingSpacing) : min(rect.maxY, contentSize.height - actualItemSize.height - leadingSpacing)
        var layoutAttributes: [UICollectionViewLayoutAttributes] = []
        while origin - maxPosition <= max(CGFloat(100.0) * .ulpOfOne * fabs(origin+maxPosition), .leastNonzeroMagnitude) {
            let indexPath = IndexPath(item: itemIndex % numberOfItems, section: itemIndex / numberOfItems)
            let attributes = layoutAttributesForItem(at: indexPath) as! GSPagerViewLayoutAttributes
            applyTransform(to: attributes, with: pagerView?.transformer)
            layoutAttributes.append(attributes)
            itemIndex += 1
            origin += self.itemSpacing
        }
        
        return layoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return GSPagerViewLayoutAttributes(forCellWith: indexPath).then {
            let rect = frame(for: indexPath)
            $0.center = CGPoint.init(x: rect.midX, y: rect.midY)
            $0.size = actualItemSize
        }
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        
        let proposedContentOffset = proposedContentOffset
        let proposedContentOffsetX: CGFloat = {
            if direction == .vertical { return proposedContentOffset.x }
            let translation = -collectionView.panGestureRecognizer.translation(in: collectionView).x
            var offset: CGFloat = round(proposedContentOffset.x / itemSpacing) * itemSpacing
            let minFlippingDistance = min(0.5 * itemSpacing,150)
            let originalContentOffsetX = collectionView.contentOffset.x - translation
            if abs(translation) <= minFlippingDistance {
                if abs(velocity.x) >= 0.3 && abs(proposedContentOffset.x - originalContentOffsetX) <= itemSpacing*0.5 {
                    offset += self.itemSpacing * (velocity.x)/abs(velocity.x)
                }
            }
            return offset
        }()
        let proposedContentOffsetY: CGFloat = {
            if direction == .horizontal { return proposedContentOffset.y }
            let translation = -collectionView.panGestureRecognizer.translation(in: collectionView).y
            var offset: CGFloat = round(proposedContentOffset.y / itemSpacing) * itemSpacing
            let minFlippingDistance = min(0.5 * itemSpacing,150)
            let originalContentOffsetY = collectionView.contentOffset.y - translation
            if abs(translation) <= minFlippingDistance {
                if abs(velocity.y) >= 0.3 && abs(proposedContentOffset.y - originalContentOffsetY) <= itemSpacing*0.5 {
                    offset += self.itemSpacing * (velocity.y)/abs(velocity.y)
                }
            }
            return offset
        }()
        
        return CGPoint(x: proposedContentOffsetX, y: proposedContentOffsetY)
    }
}

// MARK: Internal Methods

extension GSPagerViewLayout {
    
    internal func forceInvalidate() {
        needsReprepare = true
        invalidateLayout()
    }
    
    internal func frame(for indexPath: IndexPath) -> CGRect {
        guard let collectionView = collectionView else { return CGRect.zero }
        
        let index = numberOfItems * indexPath.section + indexPath.item
        let originX = direction == .vertical ? leadingSpacing + CGFloat(index) * itemSpacing : (collectionView.frame.width - actualItemSize.width) / 2
        let originY = direction == .horizontal ? leadingSpacing + CGFloat(index) * itemSpacing : (collectionView.frame.height - actualItemSize.height) / 2
        return CGRect.init(origin: CGPoint.init(x: originX, y: originY), size: actualItemSize)
    }
    
    internal func contentOffset(for indexPath: IndexPath) -> CGPoint {
        let origin = frame(for: indexPath).origin
        guard let collectionView = collectionView else { return origin }
        
        let contentOffsetX = direction == .vertical ? origin.x - (collectionView.frame.width * 0.5 - actualItemSize.width * 0.5) : 0
        let contentOffsetY = direction == .horizontal ? origin.y - (collectionView.frame.height * 0.5 - actualItemSize.height * 0.5) : 0
        return CGPoint.init(x: contentOffsetX, y: contentOffsetY)
    }
}

// MARK: Private Methods

extension GSPagerViewLayout {
    
    fileprivate func adjustCollectionViewBounds() {
        guard let collectionView = collectionView, let pagerView = pagerView else { return }
        let currentIndex = max(0, min(pagerView.currentIndex, pagerView.numberOfItems - 1))
        let newIndexPath = IndexPath.init(row: currentIndex, section: isInfinite ? self.numberOfSections / 2 : 0)
        let origin = contentOffset(for: newIndexPath)
        collectionView.bounds = CGRect.init(origin: origin, size: collectionView.frame.size)
        pagerView.currentIndex = currentIndex
    }
    
    fileprivate func applyTransform(to attributes: GSPagerViewLayoutAttributes, with transformer: GSPagerViewTransformer?) {
        guard let collectionView = collectionView, let transformer = transformer else { return }
        
        switch direction {
        case .horizontal:
            attributes.position = (attributes.center.x - collectionView.bounds.midX) / itemSpacing
        case .vertical:
            attributes.position = (attributes.center.y - collectionView.bounds.midY) / itemSpacing
        }
        
        attributes.zIndex = numberOfItems - Int(attributes.position)
        transformer.apply(to: attributes)
    }
}


