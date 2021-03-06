//
//  EPCalendarPicker.swift
//  EPCalendar
//
//  Created by Prabaharan Elangovan on 02/11/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

@objc public protocol EPCalendarPickerDelegate{
    
    optional    func epCalendarPicker(_: EPCalendarPicker, didCancel error : NSError)
    optional    func epCalendarPicker(_: EPCalendarPicker, didSelectDate date : NSDate)
    optional    func epCalendarPicker(_: EPCalendarPicker, didSelectMultipleDate dates : [NSDate])
    
}


public class EPCalendarPicker: UICollectionViewController {

    public var calendarDelegate : EPCalendarPickerDelegate?
    public var multiSelectEnabled: Bool
    public var showsTodaysButton: Bool = true
    private var arrSelectedDates = [NSDate]()
    public var tintColor: UIColor
    public var weekdayTintColor: UIColor
    public var weekendTintColor: UIColor
    public var todayTintColor: UIColor
    public var dateSelectionTextColor: UIColor
    public var dateSelectionCircleColor: UIColor
    public var monthTitleColor: UIColor
    public var weekdayLabelBackgroundViewColor: UIColor
    
    
    private(set) public var startYear: Int
    private(set) public var endYear: Int
    private(set) public var startDate: NSDate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Date Picker"
        self.collectionView?.delegate = self
        self.collectionView?.backgroundColor = UIColor(white: 104.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.tintColor = self.tintColor
        self.collectionView?.showsHorizontalScrollIndicator = false
        self.collectionView?.showsVerticalScrollIndicator = false


        // Register cell classes
        self.collectionView!.registerNib(UINib(nibName: "EPCalendarCell1", bundle: NSBundle(forClass: EPCalendarPicker.self )), forCellWithReuseIdentifier: reuseIdentifier)
        
                self.collectionView!.registerNib(UINib(nibName: "EPCalendarHeaderView", bundle: NSBundle(forClass: EPCalendarPicker.self )), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        inititlizeBarButtons()

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.scrollToToday()
        }
        // Do any additional setup after loading the view.
    }

    
    func inititlizeBarButtons(){
        

        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "onTouchCancelButton")
        self.navigationItem.leftBarButtonItem = cancelButton

        var arrayBarButtons  = [UIBarButtonItem]()
        
        if multiSelectEnabled {
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "onTouchDoneButton")
            arrayBarButtons.append(doneButton)
        }
        
        if showsTodaysButton {
            let todayButton = UIBarButtonItem(title: "Today", style: UIBarButtonItemStyle.Plain, target: self, action:"onTouchTodayButton")
            arrayBarButtons.append(todayButton)
            todayButton.tintColor = todayTintColor
        }
        
        self.navigationItem.rightBarButtonItems = arrayBarButtons
        
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    public convenience init(){
        self.init(startYear: EPDefaults.startYear, endYear: EPDefaults.endYear, multiSelection: EPDefaults.multiSelection, selectedDates: nil);
    }
    
    public convenience init(startYear: Int, endYear: Int) {
        self.init(startYear:startYear, endYear:endYear, multiSelection: EPDefaults.multiSelection, selectedDates: nil)
    }
    
    public convenience init(multiSelection: Bool) {
        self.init(startYear: EPDefaults.startYear, endYear: EPDefaults.endYear, multiSelection: multiSelection, selectedDates: nil)
    }
    
    public convenience init(startYear: Int, endYear: Int, multiSelection: Bool) {
        self.init(startYear: EPDefaults.startYear, endYear: EPDefaults.endYear, multiSelection: multiSelection, selectedDates: nil)
    }
    
    public init(startYear: Int, endYear: Int, multiSelection: Bool, selectedDates: [NSDate]?) {
        
        self.startYear = startYear
        self.endYear = endYear
        self.startDate = selectedDates?.last
        
        self.multiSelectEnabled = multiSelection
        
        //Text color initializations
        self.tintColor = EPDefaults.tintColor
        self.weekdayTintColor = EPDefaults.weekdayTintColor
        self.weekendTintColor = EPDefaults.weekendTintColor
        self.dateSelectionTextColor = EPDefaults.dateSelectionTextColor
        self.dateSelectionCircleColor = EPDefaults.dateSelectionCircleColor
        self.monthTitleColor = EPDefaults.monthTitleColor
        self.todayTintColor = EPDefaults.todayTintColor
        self.weekdayLabelBackgroundViewColor = EPDefaults.weekdayLabelBackgroundViewColor

        //Layout creation
        let layout = UICollectionViewFlowLayout()
        //layout.sectionHeadersPinToVisibleBounds = true  // If you want make a floating header enable this property(Avaialble after iOS9)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        layout.headerReferenceSize = EPDefaults.headerSize
        if let _ = selectedDates  {
            self.arrSelectedDates.appendContentsOf(selectedDates!)
        }
        super.init(collectionViewLayout: layout)
        
    }
    

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UICollectionViewDataSource

    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        if startYear > endYear {
//            return 0
//        }
//        
//        let numberOfMonths = 12 * (endYear - startYear) + 12
//        return numberOfMonths
//        
        return 1
    }


    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let startDate = startDate {
            let firstDayOfMonth = startDate.dateByAddingMonths(section)
            let addingPrefixDaysWithMonthDyas = ( firstDayOfMonth.numberOfDaysInMonth() + firstDayOfMonth.weekday() - NSCalendar.currentCalendar().firstWeekday )
            let addingSuffixDays = addingPrefixDaysWithMonthDyas%7
            var totalNumber  = addingPrefixDaysWithMonthDyas
            if addingSuffixDays != 0 {
                totalNumber = totalNumber + (7 - addingSuffixDays)
            }
            
            return totalNumber
        }
        else {
            return 0
        }
    }

    override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! EPCalendarCell1
        
        let calendarStartDate = NSDate(year:startYear, month: 2, day: 1)
        let firstDayOfThisMonth = calendarStartDate.dateByAddingMonths(indexPath.section)
        let prefixDays = ( firstDayOfThisMonth.weekday() - NSCalendar.currentCalendar().firstWeekday)
        
        if indexPath.row >= prefixDays {
            cell.isCellSelectable = true
            
            cell.lblDay.hidden = false

            let currentDate = firstDayOfThisMonth.dateByAddingDays(indexPath.row-prefixDays)
            let nextMonthFirstDay = firstDayOfThisMonth.dateByAddingDays(firstDayOfThisMonth.numberOfDaysInMonth()-1)
            
            cell.currentDate = currentDate
            cell.lblDay.text = "\(currentDate.day())"

            
            if arrSelectedDates.filter({ $0.isDateSameDay(currentDate)
            }).count > 0 {
                cell.selectedForLabelColor(dateSelectionTextColor, circleColor:  dateSelectionCircleColor)
            }
            else{
                cell.deSelectedForLabelColor(weekdayTintColor)
               
                if cell.currentDate.isSaturday() || cell.currentDate.isSunday() {
                    cell.lblDay.textColor = weekendTintColor
                }
                if (currentDate > nextMonthFirstDay) {
                    cell.isCellSelectable = false
                    
                    cell.lblDay.hidden = true

//                    cell.lblDay.textColor = EPColors.LightGrayColor
                }
                if currentDate.isToday() {
                    cell.setTodayCellColor(todayTintColor)
                }
               
            }
        }
        else {
            cell.isCellSelectable = false
            
            cell.lblDay.hidden = true

            let previousDay = firstDayOfThisMonth.dateByAddingDays(-( prefixDays - indexPath.row))
            cell.currentDate = previousDay
//            cell.lblDay.text = "\(previousDay.day())"
//            cell.lblDay.textColor = EPColors.LightGrayColor
//            cell.lblDay.layer.backgroundColor = UIColor.clearColor().CGColor
        }
        return cell
    }

    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        
        let rect = UIScreen.mainScreen().bounds
        let screenWidth = rect.size.width - 7
        return CGSizeMake(screenWidth/7, (screenWidth/7) * 0.65);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(0, 0, 5, 0); //top,left,bottom,right
    }
    
    override public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", forIndexPath: indexPath) as! EPCalendarHeaderView
            
            if let startDate = startDate {
                let firstDayOfMonth = startDate.dateByAddingMonths(indexPath.section)
                
                header.lblTitle.text = firstDayOfMonth.monthNameFull()
            }
            
            
            header.lblTitle.textColor = monthTitleColor
            
            header.weekdayLabelBackgroundView.backgroundColor = weekdayLabelBackgroundViewColor
            
            header.updateWeekdaysLabelColor(UIColor(white: 155.0/255.0, alpha: 1.0))
            header.updateWeekendLabelColor(UIColor(white: 155.0/255.0, alpha: 1.0))
        
            return header;
        }

        return UICollectionReusableView()
        
    }
    
    override public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! EPCalendarCell1
        
        cell.selectedForLabelColor(dateSelectionTextColor, circleColor: dateSelectionCircleColor)

        for aCell in collectionView.visibleCells() {
            if aCell != cell {
                if let calendarCell = aCell as? EPCalendarCell1 {
                    calendarCell.deSelectedForLabelColor(weekdayTintColor)
                }
            }
        }
        
        calendarDelegate?.epCalendarPicker!(self, didSelectDate: cell.currentDate)

/*
        if !multiSelectEnabled {
            calendarDelegate?.epCalendarPicker!(self, didSelectDate: cell.currentDate)
            cell.selectedForLabelColor(dateSelectionColor)
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        if cell.isCellSelectable! {
            if arrSelectedDates.filter({ $0.isDateSameDay(cell.currentDate)
            }).count == 0 {
                arrSelectedDates.append(cell.currentDate)
                cell.selectedForLabelColor(dateSelectionColor)
                
                if cell.currentDate.isToday() {
                    cell.setTodayCellColor(dateSelectionColor)
                }
            }
            else {
                arrSelectedDates = arrSelectedDates.filter(){
                    return  !($0.isDateSameDay(cell.currentDate))
                }
                if cell.currentDate.isSaturday() || cell.currentDate.isSunday() {
                    cell.deSelectedForLabelColor(weekendTintColor)
                }
                else {
                    cell.deSelectedForLabelColor(weekdayTintColor)
                }
                if cell.currentDate.isToday() {
                    cell.setTodayCellColor(todayTintColor)
                }
            }
        }
     */
    }
    
    //MARK: Button Actions
    
    internal func onTouchCancelButton() {
       //TODO: Create a cancel delegate
        calendarDelegate?.epCalendarPicker!(self, didCancel: NSError(domain: "EPCalendarPickerErrorDomain", code: 2, userInfo: [ NSLocalizedDescriptionKey: "User Canceled Selection"]))
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    internal func onTouchDoneButton() {
        //gathers all the selected dates and pass it to the delegate
        calendarDelegate?.epCalendarPicker!(self, didSelectMultipleDate: arrSelectedDates)
        dismissViewControllerAnimated(true, completion: nil)
    }

    internal func onTouchTodayButton() {
        scrollToToday()
    }
    
    
    public func scrollToToday () {
        let today = NSDate()
        scrollToMonthForDate(today)
    }
    
    public func scrollToMonthForDate (date: NSDate) {

//        let month = date.month()
//        let year = date.year()
//        let section = ((year - startYear) * 12) + month
//        let indexPath = NSIndexPath(forRow:1, inSection: section-1)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        
        self.collectionView?.scrollToIndexpathByShowingHeader(indexPath)
    }
    
    
}
