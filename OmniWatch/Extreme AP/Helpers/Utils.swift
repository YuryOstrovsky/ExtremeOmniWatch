//
//  Utils.swift
//  Extreme AP
//
//  Created by Dmitry Voronov on 2019-05-14.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation

class Utils {
    static func formatChartLabelBytes(labelIndex: Int, labelValue: Double) -> String {
        return renderBytes(valueNullable: labelValue)
    }
    
    static func renderBytes (valueNullable: Double?) -> String {
        if valueNullable == nil {
            return "0 bytes";
        }
        var value : Double = valueNullable!
        var ret = ""
        if value >= 1000000000000 {
            value = (value / 1099511627776)
            value = roundedToPlaces(val: value, places: 1)
            return String(value) + " TB";
        } else if value >= 1000000000 {
            value = value / 1073741824;
            value = roundedToPlaces(val: value, places: 1)
            return String(value) + " GB";
        }   else if value >= 1000000 {
            value = value / 1048576;
            value = roundedToPlaces(val: value, places: 1)
            return String(value) + " MB";
        } else if value >= 1000 {
            //render it as kb w/ 2 decimal places
            value = value / 1024
            value = roundedToPlaces(val: value, places: 1)
            return String(value) + " kB";
        } else {
            value = roundedToPlaces(val: value, places: 1)
            return String(value) + " bytes";
        }
    
    }
    
    static func roundedToPlaces(val: Double, places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (val * divisor).rounded() / divisor
    }
    
    static func renderChannelValue(channel: Int?) -> String {
        if channel == nil{
            return "";
        }
        var channelValue = channel!
    
        var rendered = "2400";
        var offset = (channelValue & 0x00FF0000) >> 16;
        var freq = (channelValue & 0x0000FFFF) + 20 * offset;
        var widths : [Int] = [];
        if freq > 5000 {
            widths = [0, 20, 40, 80, 80];
        } else {
            widths = [0, 20, 40, 40, 80];
        }
    
        var chanWidth = widths[(channelValue & 0xFF000000) >> 24];
    
    
        var channel = self.frequencyToChannel(freq: freq);
        if freq == -1 {
            rendered = "None";
        } else if freq == 0 {
            rendered = "None";
        } else if freq > 0 && freq < 10 { //acs
            rendered = "N/A";
        } else if chanWidth == 20 {
            rendered = channel + ":(" + String(freq) + ")";
        } else {
            var baseFreq = self.getBaseFrequency(freq: freq, offset: offset);
            if baseFreq > 5000 {
                var w = chanWidth / 20;
                var freqs : [String] = []
                rendered = channel + ": (";
                for i in 0...w {
                    if i == offset {
                        freqs.append("[" + String(baseFreq + i * 20) + "]");
                    } else {
                        freqs.append(String(baseFreq + i * 20))
                    }
                }
                rendered = rendered + freqs.joined(separator: ",") + ")";
            } else {
                if offset == 0 {
                    rendered = channel + "+("  + String(freq) + "," + String(freq + 20) + ")";
                } else {
                    rendered  = channel + "-(" + String(freq) + "," + String(freq - 20) + ")";
                }
            }
        }
    
        return rendered;
    }
    
    static func frequencyToChannel(freq: Int) -> String {
        if freq == -1 {
            return "-1"
        }
        if freq < 2407 {
            return "0"
        }
        if freq < 2480 {
            return String((freq - 2407) / 5)
        }
        if freq < 5000 {
            return String((freq - 2414) / 5)
        }
        return String((freq - 5000) / 5)
    }
    
    static func getBaseFrequency(freq: Int, offset: Int) -> Int {
        return freq - 20 * offset;
    }

}
