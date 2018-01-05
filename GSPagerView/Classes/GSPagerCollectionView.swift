//
//  GSPagerCollectionView.swift
//  GSPagerView
//
//  Created by 孟钰丰 on 2017/12/22.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import GSStability

class GSPagerViewCollectionView: UICollectionView {
    
    fileprivate var pagerView: GSPagerView? { return self.superview?.superview as? GSPagerView }
    
    #if !os(tvOS)
    override var scrollsToTop: Bool {
        set { super.scrollsToTop = false }
        get { return false }
    }
    #endif
    
    override var contentInset: UIEdgeInsets {
        set {
            super.contentInset = .zero
            if (newValue.top > 0) { self.contentOffset = CGPoint(x:self.contentOffset.x, y:self.contentOffset.y+newValue.top) }
        }
        get { return super.contentInset }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        self.do {
            $0.contentInset = .zero
            $0.decelerationRate = UIScrollViewDecelerationRateFast
            $0.showsVerticalScrollIndicator = false
            $0.showsHorizontalScrollIndicator = false
            if #available(iOS 10.0, *) {
                $0.isPrefetchingEnabled = false
            }
            if #available(iOS 11.0, *) {
                $0.contentInsetAdjustmentBehavior = .never
            }
            #if !os(tvOS)
                $0.scrollsToTop = false
                $0.isPagingEnabled = false
            #endif
        }
        
    }
    
}

