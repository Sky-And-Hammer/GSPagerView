//
//  CollectionView.swift
//  GSPagerView
//
//  Created by 孟钰丰 on 2017/12/21.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import GSUIKit

internal class GSCollectionView: UICollectionView {
    
    fileprivate var pagerView: GSPagerView? { return superview?.superview as? GSPagerView }
    
    override var scrollsToTop: Bool {
        set { super.scrollsToTop = false }
        get { return false }
    }
    
    override var contentInset: UIEdgeInsets {
        set {
            super.contentInset = .zero
            if newValue.top > 0 {
                contentOffset = CGPoint.init(x: contentOffset.x, y: contentOffset.y + newValue.top)
            }
        }
        get { return super.contentInset }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        self.do {
            $0.contentInset = UIEdgeInsets.zero
            $0.decelerationRate = UIScrollViewDecelerationRateFast
            $0.showsVerticalScrollIndicator = false
            $0.showsHorizontalScrollIndicator = false
            if #available(iOS 10.0, *) {
                $0.isPrefetchingEnabled = false
            }
            
            $0.scrollsToTop = false
            $0.isPagingEnabled = false
        }
    }
}
