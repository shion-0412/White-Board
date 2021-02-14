//
//  AppDelegate.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/02.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var initialViewControllerDelegate: InitialViewControllerDelegate?
    
    @IBAction func undo(_ sender: Any) {
        initialViewControllerDelegate?.undo()
    }
    
    @IBAction func redo(_ sender: Any) {
        initialViewControllerDelegate?.redo()
    }
    
    @IBAction func saveAsPng(_ sender: Any) {
        initialViewControllerDelegate?.saveAsPng()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

protocol InitialViewControllerDelegate: class {
    func undo()
    func redo()
    func saveAsPng()
}
