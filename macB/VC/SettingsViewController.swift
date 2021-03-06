//
//  SettingsViewController.swift
//  macB
//
//  Created by Denis Dobanda on 06.01.19.
//  Copyright © 2019 Denis Dobanda. All rights reserved.
//

import Cocoa

enum FontNames: String {
    case timesNewRoman = "TimesNewRomanPSMT"
    case timesNewRomanBold = "TimesNewRomanPS-BoldMT"
    
    case georgia = "Georgia"
    case georgiaBold = "Georgia-Bold"
    
    case arial = "ArialMT"
    case arialBold = "Arial-BoldMT"
    
    case helvetica = "Helvetica"
    case helveticaBold = "Helvetica-Bold"
}

class SettingsViewController: NSViewController {

    @IBOutlet weak var strongsSwitch: NSButton!
    @IBOutlet weak var tooltipSwitch: NSButton!
    @IBOutlet weak var fontCombo: NSComboBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        strongsSwitch.state = AppDelegate.plistManager.isStrongsIsOn ? .on : .off
        tooltipSwitch.state = AppDelegate.plistManager.isTooltipOn ? .on : .off
        addFontItem(.timesNewRoman, with: "Times New Roman")
        addFontItem(.georgia, with: "Georgia")
        addFontItem(.arial, with: "Arial")
        addFontItem(.helvetica, with: "Helvetica")
        
        switch AppDelegate.plistManager.getFont() {
        case FontNames.timesNewRoman.rawValue:
            fontCombo.selectItem(at: 0)
        case FontNames.georgia.rawValue:
            fontCombo.selectItem(at: 1)
        case FontNames.arial.rawValue:
            fontCombo.selectItem(at: 2)
        case FontNames.helvetica.rawValue:
            fontCombo.selectItem(at: 3)
        default: break
        }
    }
    
    @IBAction func chosedFont(_ sender: NSComboBox) {
        switch sender.indexOfSelectedItem {
        case 0:
            setFont(.timesNewRoman, bold: .timesNewRomanBold)
        case 1:
            setFont(.georgia, bold: .georgiaBold)
        case 2:
            setFont(.arial, bold: .arialBold)
        case 3:
            setFont(.helvetica, bold: .helveticaBold)
        default:
            break
        }
    }
    
    private func addFontItem(_ font: FontNames, with name: String) {
        let f = NSAttributedString(
            string: name,
            attributes: [
                .font : NSFont(name: font.rawValue, size: 15)!
            ]
        )
        fontCombo.addItem(withObjectValue: f)
    }
    
    private func setFont(_ font: FontNames, bold: FontNames) {
        AppDelegate.plistManager.setFont(named: font.rawValue)
        AppDelegate.plistManager.setFontBold(named: bold.rawValue)
        AppDelegate.updateManagers()
    }
    
    @IBAction func strongsCheck(_ sender: NSButton) {
        AppDelegate.coreManager.strongsNumbersIsOn = sender.state.rawValue != 0
    }
    
    @IBAction func tooltipAction(_ sender: NSButton) {
        AppDelegate.plistManager.isTooltipOn = sender.state == .on
    }
    
}
