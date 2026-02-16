import SwiftUI

struct ContentView: View {
    @State private var viewModel = BabyProgressViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 50))
            
            Text("BabyLoading")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 20)
            
            Text("When is the big event?")
                .font(.headline)
            
            DatePicker("Event Date", selection: $viewModel.eventDate, displayedComponents: [.date])
            .datePickerStyle(.graphical)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            .onChange(of: viewModel.eventDate) { _, newDate in
                viewModel.updateDate(newDate)
            }
            
            if let days = viewModel.daysRemaining {
                Text("\(days) days remaining")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
