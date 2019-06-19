//
//  APReportsTVC.swift
//  Extreme AP
//
//  Created by Dmitry Voronov on 2019-05-07.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit
import SwiftChart

class APReportsTVC : UIViewController, ChartDelegate {
    
    private var rfQualityChart : Chart?
    private var channelUtilChart : Chart?
    private var throughputChart : Chart?
    @IBOutlet weak var labelLeadingMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generateCharts()
    }
    
    private func generateCharts() {
        
        var frame = CGRect(x: 10, y: 130, width: self.view.frame.width * 0.95, height: self.view.frame.height / 2 - 130)
        
        var rfQualityData : [Double] = []//[(x:Double, y:Double)] = []
        var allLabels : [Double] = []
        APManager.shared.currentAPRFQualityReport?.forEach { rfQualityEntry in
            let date = floor(rfQualityEntry.timestamp ?? 0)
            var value = Double(rfQualityEntry.rfQualityRadio ?? "0")
            if value != nil {
                value = value! > 5.0 ? 5.0 : value;
            }
            //rfQualityData.append((x: date, y: value ?? 0))
            rfQualityData.append(value ?? 0)
            allLabels.append(date)
        }
        
        rfQualityChart = createAreaChart(frame: frame, seriesName: "RF Quality", series: rfQualityData, labels: allLabels)
        /*
        frame = CGRect(x: 10, y: self.view.frame.height / 2 + 50, width: self.view.frame.width * 0.95, height: self.view.frame.height / 2 - 130)
        
        var chUtil24Data : [Double] = []//[(x:Double, y:Double)] = []
        var utilLabels  : [Double] = []
        APManager.shared.channelUtilReport24?.channelUtilizationInfoArr![0].values!.forEach { utilEntry in
            let date = floor(utilEntry.timestamp ?? 0)
            let value = Double(utilEntry.channelUtil ?? "0")
            //rfQualityData.append((x: date, y: value ?? 0))
            chUtil24Data.append(value ?? 0)
            utilLabels.append(date)
        }
        var chUtil5Data : [Double] = []
        APManager.shared.channelUtilReport5?.channelUtilizationInfoArr![0].values!.forEach { utilEntry in
            let value = Double(utilEntry.channelUtil ?? "0")
            chUtil5Data.append(value ?? 0)
        }
        
        channelUtilChart = createAreaChart(frame: frame, seriesName: "2.4 GHz", series: chUtil24Data, series2Name: "5 GHz", series2: chUtil5Data, labels: utilLabels)
 */
        frame = CGRect(x: 10, y: self.view.frame.height / 2 + 50, width: self.view.frame.width * 0.95, height: self.view.frame.height / 2 - 130)
        var throughputData : [Double] = []
        var throughputLabels : [Double] = []
        APManager.shared.throughputReport?.forEach { timeseriesValue in
            let date = floor(timeseriesValue.timestamp ?? 0)
            let value = timeseriesValue.value ?? 0
            //rfQualityData.append((x: date, y: value ?? 0))
            throughputData.append(value)
            throughputLabels.append(date)
        }
        
        throughputChart = createAreaChart(frame: frame, seriesName: "Throughput", series: throughputData, labels: throughputLabels, yLabelFormatter: Utils.formatChartLabelBytes)
    }
    
    func createAreaChart(frame: CGRect, seriesName: String, series: [Double], series2Name: String? = nil, series2: [Double]? = nil, labels: [Double], yLabelFormatter: Any? = nil) -> Chart {
        var valueLabels : [Double] = []
        var displayLabels : [Double] = []
        let labelJump = max(1, Int(10*(Double(labels.count)/10).rounded()) / 5);
        for (i, value) in labels.enumerated() {
            if i % labelJump == 0 {
                valueLabels.append(Double(i))
                displayLabels.append(value)
            }
        }
        
        let chart = Chart(
            frame: frame
        )
        chart.xLabels = valueLabels
        chart.delegate = self
        let series = ChartSeries(series)
        series.area = true
        series.color = ChartColors.purpleColor()
        if series2 != nil {
            let series2 = ChartSeries(series2!)
            series2.area = true
            series2.color = ChartColors.blueColor()
            chart.add([series, series2])
        } else {
            chart.add(series)
        }
        
        chart.labelFont = UIFont.systemFont(ofSize: 12)
        chart.minY = 0
        if yLabelFormatter != nil {
            chart.yLabelsFormatter = yLabelFormatter as! (Int, Double) -> String
        } else {
            chart.yLabelsFormatter = {(labelIndex: Int, labelValue: Double) -> String in
                return String(Int(labelValue))
            }
        }
        chart.xLabelsSkipLast = true
        chart.xLabelsFormatter = { (labelIndex: Int, labelValue: Double) -> String in
            let label = displayLabels[labelIndex]
            let date = Date(timeIntervalSince1970: label/1000)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "h:mm a" //Specify your format that you want
            let labelStr = dateFormatter.string(from: date)
            return labelStr
        }
        
        self.view.addSubview(chart)
        
        return chart;
    }
    
    func didTouchChart(_ chart: Chart, indexes: Array<Int?>, x: Double, left: CGFloat) {
        /*
        if let value = chart.valueForSeries(0, atIndex: indexes[0]) {
            
            let numberFormatter = NumberFormatter()
            numberFormatter.minimumFractionDigits = 2
            numberFormatter.maximumFractionDigits = 2
            label.text = numberFormatter.string(from: NSNumber(value: value))
            
            // Align the label to the touch left position, centered
            var constant = labelLeadingMarginInitialConstant + left - (label.frame.width / 2)
            
            // Avoid placing the label on the left of the chart
            if constant < labelLeadingMarginInitialConstant {
                constant = labelLeadingMarginInitialConstant
            }
            
            // Avoid placing the label on the right of the chart
            let rightMargin = chart.frame.width - label.frame.width
            if constant > rightMargin {
                constant = rightMargin
            }
            
            labelLeadingMarginConstraint.constant = constant
            
        }*/
        
    }
    
    func didFinishTouchingChart(_ chart: Chart) {
        
    }
    
    func didEndTouchingChart(_ chart: Chart) {
        
    }
}
