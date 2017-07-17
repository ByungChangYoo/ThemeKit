//
//  WindowController.swift
//  Demo
//
//  Created by Nuno Grilo on 29/09/2016.
//  Copyright © 2016 Paw & Nuno Grilo. All rights reserved.
//

import Cocoa
import ThemeKit

class WindowController: NSWindowController {
    
    public var themeKit: ThemeManager = ThemeManager.shared
    
    override func windowDidLoad() {
        // Observe note selection change notifications
        NotificationCenter.default.addObserver(forName: .didChangeNoteSelection, object: nil, queue: nil) { (notification) in
            let obj = notification.object
            if let note = notification.userInfo?["note"] as? Note,
                let viewController = obj as? NSViewController,
                viewController.view.window == self.window {
                self.updateTitle(note)
            }
        }
        
        // Observe note text edit notifications
        NotificationCenter.default.addObserver(forName: .didEditNoteText, object: nil, queue: nil) { (notification) in
            let obj = notification.object
            if let note = notification.userInfo?["note"] as? Note,
                let viewController = obj as? NSViewController,
                viewController.view.window == self.window {
                self.updateTitle(note)
            }
        }
        
        // Observe theme change notifications
        NotificationCenter.default.addObserver(forName: .didChangeTheme, object: nil, queue: nil) { (notification) in
            // update KVO property
            self.willChangeValue(forKey: "canEditTheme")
            self.didChangeValue(forKey: "canEditTheme")
        }
    }
    
    /// Add titlebar overlay view.
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let titlebarView = self.titlebarView {
            // create titlebar background overlay view
            let overlayView = TitleBarOverlayView(frame: NSMakeRect(0, 0, 100, 100))
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            
            // add overlay view below everything else
            titlebarView.addSubview(overlayView, positioned: .below, relativeTo: nil)
            
            // add constraints
            let constraintViews = ["view":overlayView]
            titlebarView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [.directionLeadingToTrailing], metrics: nil, views: constraintViews))
            titlebarView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [.directionLeadingToTrailing], metrics: nil, views: constraintViews))
            
            // refresh it when key flag changes
            NotificationCenter.default.addObserver(forName: .NSWindowDidBecomeKey, object: window, queue: nil, using: { _ in
                overlayView.needsDisplay = true
            })
            NotificationCenter.default.addObserver(forName: .NSWindowDidResignKey, object: window, queue: nil, using: { _ in
                overlayView.needsDisplay = true
            })
        }
    }
    
    /// Find `NSTitlebarContainerView` view.
    private var titlebarView: NSView? {
        if let themeFrame = self.window?.contentView?.superview {
            for subview in themeFrame.subviews {
                if subview.className == "NSTitlebarContainerView" {
                    return subview.subviews.first
                }
            }
        }
        return nil
    }
    
    /// Update window title with current note title.
    func updateTitle(_ note: Note) {
        self.window?.title = "\(note.title) - ThemeKit Demo"
    }
    
    /// Can edit current theme (must be a `UserTheme`).
    var canEditTheme: Bool {
        return ThemeManager.shared.theme.isUserTheme
    }
    
    /// Edit current (`UserTheme`) theme.
    @IBAction func editTheme(_ sender: Any) {
        if ThemeManager.shared.theme.isUserTheme,
            let userTheme = ThemeManager.shared.theme as? UserTheme,
            let userThemeURL = userTheme.fileURL {
            
            guard FileManager.default.isWritableFile(atPath: userThemeURL.path) else {
                let alert = NSAlert()
                alert.messageText = "Theme file is not writable."
                alert.informativeText = "If you're lunching Demo from the Downloads folder, move it to another place and try again."
                alert.alertStyle = NSAlertStyle.critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }
            
            // check if there is any app associted with `.theme` extension
            let userThemeCFURL:CFURL = userThemeURL as CFURL
            if let _ = LSCopyDefaultApplicationURLForURL(userThemeCFURL, .editor, nil) {
                NSWorkspace.shared().open(userThemeURL)
            }
            else {
                // otherwise open with TextEdit
                NSWorkspace.shared().openFile(userThemeURL.path, withApplication: "TextEdit", andDeactivate: true)
            }
            
        }
    }
    
}
