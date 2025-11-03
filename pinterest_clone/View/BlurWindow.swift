//
//  BlurWindow.swift
//  pinterest_clone
//
//  Created by Realwat2007 on 30/10/25.
//

import SwiftUI

struct BlurWindow: NSViewRepresentable {
    func makeNSView(context: Context)-> NSVisualEffectView{
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        
    }
}

#Preview {
    BlurWindow()
}
