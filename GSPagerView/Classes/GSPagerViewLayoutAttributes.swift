//
//  GSPagerViewLayoutAttributes.swift
//  GSPagerView
//
//  Created by 孟钰丰 on 2017/12/22.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

open class GSPagerViewLayoutAttributes: UICollectionViewLayoutAttributes {
    
    open var position: CGFloat = 0
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? GSPagerViewLayoutAttributes else { return false }
        var isEqual = super.isEqual(object)
        isEqual = isEqual && (self.position == object.position)
        return isEqual
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! GSPagerViewLayoutAttributes
        copy.position = self.position
        return copy
    }
    
}

