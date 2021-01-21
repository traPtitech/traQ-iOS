//
//  ContentView.swift
//  traQ
//
//  Created by spa on 2021/01/21.
//

import SwiftUI


struct ContentView: View {
    @EnvironmentObject var state: ApplicationStore
    
    var body: some View {
        WebView(url: $state.url)
            .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.red)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.host, traQConstants.defaultHost)
    }
}
