//
//  SpamoApp.swift
//  Spamo
//
//  Created by Ben Blodgett on 11/9/24.
//

import SwiftUI

@main
struct SpamoApp: App {
    @State var content: ContentView = ContentView()
    var body: some Scene {
        WindowGroup {
            content
        }
    }
}
