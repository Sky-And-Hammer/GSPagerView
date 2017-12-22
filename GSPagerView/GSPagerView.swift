//
//  GSPagerView.swift
//  GSPagerView
//
//  Created by 孟钰丰 on 2017/12/21.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

// MARK: GSPagerViewDataSource

public protocol GSPagerViewDataSource: class {
    
    /// Asks your data source object for the number of items in the pager view.
    func numberOfItems(in pagerView: GSPagerView) -> Int
    /// Asks your data source object for the cell that corresponds to the specified item in the pager view.
    func pagerView(_ pagerView: GSPagerView, cellForItemAt index: Int) -> UICollectionViewCell
}

// MARK: GSPagerViewDataSource

@objc public protocol GSPagerViewDelegate: class {
    
    /// Asks the delegate if the item should be highlighted during tracking.
    @objc optional func pagerView(_ pagerView: GSPagerView, shouldHighlightItemAt index: Int) -> Bool
    
    /// Tells the delegate that the item at the specified index was highlighted.
    @objc optional func pagerView(_ pagerView: GSPagerView, didHighlightItemAt index: Int)
    
    /// Asks the delegate if the specified item should be selected.
    @objc optional func pagerView(_ pagerView: GSPagerView, shouldSelectItemAt index: Int) -> Bool
    
    /// Tells the delegate that the item at the specified index was selected.
    @objc optional func pagerView(_ pagerView: GSPagerView, didSelectItemAt index: Int)
    
    /// Tells the delegate that the specified cell is about to be displayed in the pager view.
    @objc optional func pagerView(_ pagerView: GSPagerView, willDisplay cell: UICollectionViewCell, forItemAt index: Int)
    
    /// Tells the delegate that the specified cell was removed from the pager view.
    @objc optional func pagerView(_ pagerView: GSPagerView, didEndDisplaying cell: UICollectionViewCell, forItemAt index: Int)
    
    /// Tells the delegate when the pager view is about to start scrolling the content.
    @objc optional func pagerViewWillBeginDragging(_ pagerView: GSPagerView)
    
    /// Tells the delegate when the user finishes scrolling the content.
    @objc optional func pagerViewWillEndDragging(_ pagerView: GSPagerView, targetIndex: Int)
    
    /// Tells the delegate when the user scrolls the content view within the receiver.
    @objc optional func pagerViewDidScroll(_ pagerView: GSPagerView)
    
    /// Tells the delegate when a scrolling animation in the pager view concludes.
    @objc optional func pagerViewDidEndScrollAnimation(_ pagerView: GSPagerView)
    
    /// Tells the delegate that the pager view has ended decelerating the scrolling movement.
    @objc optional func pagerViewDidEndDecelerating(_ pagerView: GSPagerView)
}

// MARK: GSPagerViewDirection
public enum GSPagerViewDirection {
    case horizontal, vertical
}

@IBDesignable
open class GSPagerView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Public properties
    
    #if TARGET_INTERFACE_BUILDER
    // Yes you need to lie to the Interface Builder, otherwise "@IBOutlet" cannot be connected.
    @IBOutlet open weak var dataSource: AnyObject?
    @IBOutlet open weak var delegate: AnyObject?
    #else
    open weak var dataSource: GSPagerViewDataSource?
    open weak var delegate: GSPagerViewDelegate?
    #endif
    
    /// The scroll direction of the pager view. Default is horizontal.
    open var scrollDirection: GSPagerViewDirection = .horizontal {
        didSet {
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    /// The time interval of automatic sliding. 0 means disabling automatic sliding. Default is 0.
    @IBInspectable
    open var automaticSlidingInterval: CGFloat = 0.0 {
        didSet {
            self.cancelTimer()
            if self.automaticSlidingInterval > 0 {
                self.startTimer()
            }
        }
    }
    
    /// The spacing to use between items in the pager view. Default is 0.
    @IBInspectable
    open var interitemSpacing: CGFloat = 0 {
        didSet {
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    @IBInspectable
    open override var clipsToBounds: Bool {
        didSet {
            self.collectionView.clipsToBounds = self.clipsToBounds
        }
    }
    
    /// The item size of the pager view. .zero means always fill the bounds of the pager view. Default is .zero.
    @IBInspectable
    open var itemSize: CGSize = .zero {
        didSet {
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    /// A Boolean value indicates that whether the pager view has infinite items. Default is false.
    @IBInspectable
    open var isInfinite: Bool = false {
        didSet {
            self.collectionViewLayout.needsReprepare = true
            self.collectionView.reloadData()
        }
    }
    
    /// A Boolean value that determines whether bouncing always occurs when horizontal scrolling reaches the end of the content view.
    @IBInspectable
    open var alwaysBounceHorizontal: Bool = false {
        didSet {
            self.collectionView.alwaysBounceHorizontal = self.alwaysBounceHorizontal;
        }
    }
    
    /// A Boolean value that determines whether bouncing always occurs when vertical scrolling reaches the end of the content view.
    @IBInspectable
    open var alwaysBounceVertical: Bool = false {
        didSet {
            self.collectionView.alwaysBounceVertical = self.alwaysBounceVertical;
        }
    }
    
    /// The background view of the pager view.
    @IBInspectable
    open var backgroundView: UIView? {
        didSet {
            if let backgroundView = self.backgroundView {
                if backgroundView.superview != nil {
                    backgroundView.removeFromSuperview()
                }
                self.insertSubview(backgroundView, at: 0)
                self.setNeedsLayout()
            }
        }
    }
    
    /// The transformer of the pager view.
    open var transformer: GSPagerViewTransformer? {
        didSet {
            self.transformer?.pagerView = self
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    // MARK: - Public readonly-properties
    
    /// Returns whether the user has touched the content to initiate scrolling.
    open var isTracking: Bool {
        return self.collectionView.isTracking
    }
    
    /// Remove the infinite loop if there is only one item. default is NO
    @IBInspectable
    open var removesInfiniteLoopForSingleItem: Bool = false {
        didSet {
            self.reloadData()
        }
    }
    
    /// The percentage of x position at which the origin of the content view is offset from the origin of the pagerView view.
    open var scrollOffset: CGFloat {
        let contentOffset = max(self.collectionView.contentOffset.x, self.collectionView.contentOffset.y)
        let scrollOffset = Double(contentOffset / self.collectionViewLayout.itemSpacing)
        return fmod(CGFloat(scrollOffset), CGFloat(Double(self.numberOfItems)))
    }
    
    /// The underlying gesture recognizer for pan gestures.
    open var panGestureRecognizer: UIPanGestureRecognizer {
        return self.collectionView.panGestureRecognizer
    }
    
    @objc open internal(set) var currentIndex: Int = 0
    
    // MARK: - Private properties
    
    internal weak var collectionViewLayout: GSPagerViewLayout!
    
    internal weak var contentView: UIView!
    
    internal var timer: Timer?
    internal var numberOfItems: Int = 0
    internal var numberOfSections: Int = 0
    
    fileprivate weak var collectionView: GSCollectionView!
    fileprivate var dequeingSection = 0
    fileprivate var centermostIndexPath: IndexPath {
        guard self.numberOfItems > 0, self.collectionView.contentSize != .zero else {
            return IndexPath(item: 0, section: 0)
        }
        let sortedIndexPaths = self.collectionView.indexPathsForVisibleItems.sorted { (l, r) -> Bool in
            let leftFrame = self.collectionViewLayout.frame(for: l)
            let rightFrame = self.collectionViewLayout.frame(for: r)
            var leftCenter: CGFloat,rightCenter: CGFloat,ruler: CGFloat
            switch self.scrollDirection {
            case .horizontal:
                leftCenter = leftFrame.midX
                rightCenter = rightFrame.midX
                ruler = self.collectionView.bounds.midX
            case .vertical:
                leftCenter = leftFrame.midY
                rightCenter = rightFrame.midY
                ruler = self.collectionView.bounds.midY
            }
            return abs(ruler-leftCenter) < abs(ruler-rightCenter)
        }
        let indexPath = sortedIndexPaths.first
        if let indexPath = indexPath {
            return indexPath
        }
        return IndexPath(item: 0, section: 0)
    }
    
    fileprivate var possibleTargetingIndexPath: IndexPath?
    
    
    // MARK: - Overriden functions
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundView?.frame = self.bounds
        self.contentView.frame = self.bounds
        self.collectionView.frame = self.contentView.bounds
    }
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow != nil {
            self.startTimer()
        } else {
            self.cancelTimer()
        }
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.masksToBounds = true
        let label = UILabel(frame: self.contentView.bounds)
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.text = "PagerView"
        self.contentView.addSubview(label)
    }
    
    deinit {
        self.collectionView.dataSource = nil
        self.collectionView.delegate = nil
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let dataSource = self.dataSource else {
            return 1
        }
        self.numberOfItems = dataSource.numberOfItems(in: self)
        guard self.numberOfItems > 0 else {
            return 0;
        }
        self.numberOfSections = self.isInfinite && (self.numberOfItems > 1 || !self.removesInfiniteLoopForSingleItem) ? Int(Int16.max)/self.numberOfItems : 1
        return self.numberOfSections
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numberOfItems
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        self.dequeingSection = indexPath.section
        let cell = self.dataSource!.pagerView(self, cellForItemAt: index)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let function = self.delegate?.pagerView(_:shouldHighlightItemAt:) else {
            return true
        }
        let index = indexPath.item % self.numberOfItems
        return function(self,index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pagerView(_:didHighlightItemAt:) else {
            return
        }
        let index = indexPath.item % self.numberOfItems
        function(self,index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let function = self.delegate?.pagerView(_:shouldSelectItemAt:) else {
            return true
        }
        let index = indexPath.item % self.numberOfItems
        return function(self,index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pagerView(_:didSelectItemAt:) else {
            return
        }
        self.possibleTargetingIndexPath = indexPath
        defer {
            self.possibleTargetingIndexPath = nil
        }
        let index = indexPath.item % self.numberOfItems
        function(self,index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pagerView(_:willDisplay:forItemAt:) else {
            return
        }
        let index = indexPath.item % self.numberOfItems
        function(self, cell, index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pagerView(_:didEndDisplaying:forItemAt:) else {
            return
        }
        let index = indexPath.item % self.numberOfItems
        function(self, cell, index)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.numberOfItems > 0 {
            // In case someone is using KVO
            let currentIndex = lround(Double(self.scrollOffset)) % self.numberOfItems
            if (currentIndex != self.currentIndex) {
                self.currentIndex = currentIndex
            }
        }
        guard let function = self.delegate?.pagerViewDidScroll else {
            return
        }
        function(self)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let function = self.delegate?.pagerViewWillBeginDragging(_:) {
            function(self)
        }
        if self.automaticSlidingInterval > 0 {
            self.cancelTimer()
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let function = self.delegate?.pagerViewWillEndDragging(_:targetIndex:) {
            let contentOffset = self.scrollDirection == .horizontal ? targetContentOffset.pointee.x : targetContentOffset.pointee.y
            let targetItem = lround(Double(contentOffset/self.collectionViewLayout.itemSpacing))
            function(self, targetItem % self.numberOfItems)
        }
        if self.automaticSlidingInterval > 0 {
            self.startTimer()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let function = self.delegate?.pagerViewDidEndDecelerating {
            function(self)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let function = self.delegate?.pagerViewDidEndScrollAnimation {
            function(self)
        }
    }
    
    // MARK: - Public functions
    
    /// Register a class for use in creating new pager view cells.
    ///
    /// - Parameters:
    ///   - cellClass: The class of a cell that you want to use in the pager view.
    ///   - identifier: The reuse identifier to associate with the specified class. This parameter must not be nil and must not be an empty string.
    @objc(registerClass:forCellWithReuseIdentifier:)
    open func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    /// Register a nib file for use in creating new pager view cells.
    ///
    /// - Parameters:
    ///   - nib: The nib object containing the cell object. The nib file must contain only one top-level object and that object must be of the type PagerViewCell.
    ///   - identifier: The reuse identifier to associate with the specified nib file. This parameter must not be nil and must not be an empty string.
    @objc(registerNib:forCellWithReuseIdentifier:)
    open func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.collectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    /// Returns a reusable cell object located by its identifier
    ///
    /// - Parameters:
    ///   - identifier: The reuse identifier for the specified cell. This parameter must not be nil.
    ///   - index: The index specifying the location of the cell.
    /// - Returns: A valid PagerViewCell object.
    @objc(dequeueReusableCellWithReuseIdentifier:atIndex:)
    open func dequeueReusableCell(withReuseIdentifier identifier: String, at index: Int) -> UICollectionViewCell {
        let indexPath = IndexPath(item: index, section: self.dequeingSection)
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        return cell
    }
    
    /// Return a cell object by giving indexpath
    ///
    /// - Parameter indexPath: The indexpath giving
    /// - Returns: the cell of indexpath, if nil, mean can not found cell for indexpath
    @objc(cellForItemAtIndexPath:)
    open func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
        let cell = collectionView.cellForItem(at: indexPath)
        return cell
    }
    
    /// Reloads all of the data for the collection view.
    @objc(reloadData)
    open func reloadData() {
        self.collectionViewLayout.needsReprepare = true;
        self.collectionView.reloadData()
    }
    
    /// Selects the item at the specified index and optionally scrolls it into view.
    ///
    /// - Parameters:
    ///   - index: The index path of the item to select.
    ///   - animated: Specify true to animate the change in the selection or false to make the change without animating it.
    @objc(selectItemAtIndex:animated:)
    open func selectItem(at index: Int, animated: Bool) {
        let indexPath = self.nearbyIndexPath(for: index)
        let scrollPosition: UICollectionViewScrollPosition = self.scrollDirection == .horizontal ? .centeredVertically : .centeredVertically
        self.collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }
    
    /// Deselects the item at the specified index.
    ///
    /// - Parameters:
    ///   - index: The index of the item to deselect.
    ///   - animated: Specify true to animate the change in the selection or false to make the change without animating it.
    @objc(deselectItemAtIndex:animated:)
    open func deselectItem(at index: Int, animated: Bool) {
        let indexPath = self.nearbyIndexPath(for: index)
        self.collectionView.deselectItem(at: indexPath, animated: animated)
    }
    
    /// Scrolls the pager view contents until the specified item is visible.
    ///
    /// - Parameters:
    ///   - index: The index of the item to scroll into view.
    ///   - animated: Specify true to animate the scrolling behavior or false to adjust the pager view’s visible content immediately.
    @objc(scrollToItemAtIndex:animated:)
    open func scrollToItem(at index: Int, animated: Bool) {
        guard index < self.numberOfItems else {
            fatalError("index \(index) is out of range [0...\(self.numberOfItems-1)]")
        }
        let indexPath = { () -> IndexPath in
            if let indexPath = self.possibleTargetingIndexPath, indexPath.item == index {
                defer {
                    self.possibleTargetingIndexPath = nil
                }
                return indexPath
            }
            return self.numberOfSections > 1 ? self.nearbyIndexPath(for: index) : IndexPath(item: index, section: 0)
        }()
        let contentOffset = self.collectionViewLayout.contentOffset(for: indexPath)
        self.collectionView.setContentOffset(contentOffset, animated: animated)
    }
    
    /// Returns the index of the specified cell.
    ///
    /// - Parameter cell: The cell object whose index you want.
    /// - Returns: The index of the cell or NSNotFound if the specified cell is not in the pager view.
    @objc(indexForCell:)
    open func index(for cell: UICollectionViewCell) -> Int {
        guard let indexPath = self.collectionView.indexPath(for: cell) else {
            return NSNotFound
        }
        return indexPath.item
    }
    
    // MARK: - Private functions
    
    fileprivate func commonInit() {
        
        // Content View
        let contentView = UIView(frame:CGRect.zero)
        contentView.backgroundColor = UIColor.clear
        self.addSubview(contentView)
        self.contentView = contentView
        
        // UICollectionView
        let collectionViewLayout = GSPagerViewLayout()
        let collectionView = GSCollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        self.contentView.addSubview(collectionView)
        self.collectionView = collectionView
        self.collectionViewLayout = collectionViewLayout
        
    }
    
    fileprivate func startTimer() {
        guard self.automaticSlidingInterval > 0 && self.timer == nil else {
            return
        }
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.automaticSlidingInterval), target: self, selector: #selector(self.flipNext(sender:)), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer!, forMode: .commonModes)
    }
    
    @objc
    fileprivate func flipNext(sender: Timer?) {
        guard let _ = self.superview, let _ = self.window, self.numberOfItems > 0, !self.isTracking else {
            return
        }
        let contentOffset: CGPoint = {
            let indexPath = self.centermostIndexPath
            let section = self.numberOfSections > 1 ? (indexPath.section+(indexPath.item+1)/self.numberOfItems) : 0
            let item = (indexPath.item+1) % self.numberOfItems
            return self.collectionViewLayout.contentOffset(for: IndexPath(item: item, section: section))
        }()
        self.collectionView.setContentOffset(contentOffset, animated: true)
    }
    
    fileprivate func cancelTimer() {
        guard self.timer != nil else {
            return
        }
        self.timer!.invalidate()
        self.timer = nil
    }
    
    fileprivate func nearbyIndexPath(for index: Int) -> IndexPath {
        // Is there a better algorithm?
        let currentIndex = self.currentIndex
        let currentSection = self.centermostIndexPath.section
        if abs(currentIndex-index) <= self.numberOfItems/2 {
            return IndexPath(item: index, section: currentSection)
        } else if (index-currentIndex >= 0) {
            return IndexPath(item: index, section: currentSection-1)
        } else {
            return IndexPath(item: index, section: currentSection+1)
        }
    }
}

