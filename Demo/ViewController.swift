//
//  ViewController.swift
//  Demo
//
//  Created by 孟钰丰 on 2017/12/22.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import UIKit
import GSPagerView
import GSUIKit
import GSStability
import SnapKit

class ViewController: UIViewController {

    var pagerView = GSPagerView.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.gs.add(pagerView.then {
            $0.backgroundColor = UIColor.clear
            $0.delegate = self
            $0.dataSource = self
            $0.itemSize = CGSize.init(width: view.bounds.size.width, height: 150)
            $0.interitemSpacing = 0
            $0.isInfinite = true
            $0.automaticSlidingInterval = 3
            $0.register(HomeBannerItemCell.self, forCellWithReuseIdentifier: "HomeBannerItemCell")
        }) {
            $0.leading.trailing.top.equalToSuperview()
            $0.height.equalTo(150)
        }
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: GSPagerViewDataSource, GSPagerViewDelegate {
    
    func numberOfItems(in pagerView: GSPagerView) -> Int {
        return 4
    }
    
    func pagerView(_ pagerView: GSPagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        return pagerView.dequeueReusableCell(withReuseIdentifier: "HomeBannerItemCell", at: index).then({ (cell: HomeBannerItemCell?) in
            cell?.indieDecorate(model: "model?[gs: index]?.imageUrl")
        })
    }
    
    func pagerView(_ pagerView: GSPagerView, didSelectItemAt index: Int) {
        
    }
}


fileprivate class HomeBannerItemCell: UICollectionViewCell, CellIndieable {
    
    var imageView = UIImageView.init()
    
    var model: String? {
        didSet {
//            imageView.gs.setImage(url: model)
        }
    }
    
    override func draw(_ rect: CGRect) { super.draw(rect); assembling(rect) }
    
    func assembling(_ rect: CGRect) {
        contentView.do {
            $0.gs.add(UIView.init().then {
                $0.backgroundColor = UIColor.red
            }) {
                $0.leading.top.equalToSuperview().offset(5)
                $0.bottom.trailing.equalToSuperview().offset(-5)
            }
//            $0.gs.add(imageView) {
//                $0.leading.trailing.top.bottom.equalToSuperview()
//            }
        }
    }
    
}
