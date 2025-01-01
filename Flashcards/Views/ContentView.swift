import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                NavigationLink {
                    CardListView()
                } label: {
                    Image(systemName: "list.bullet")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.cyan)
                }
                .padding(.bottom, 50)
                NavigationLink {
                    OptionsView()
                } label: {
                    Image(systemName: "gearshape")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct OptionsView: View {
    var body: some View {
        Text("TODO: Options view")
    }
}
