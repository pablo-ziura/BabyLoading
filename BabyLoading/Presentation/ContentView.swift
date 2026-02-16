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

            Text("¿Cuándo es el gran día?")
                .font(.headline)

            DatePicker("Fecha del evento", selection: $viewModel.eventDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .onChange(of: viewModel.eventDate) { _, newDate in
                    viewModel.updateDate(newDate)
                }

            if let days = viewModel.daysRemaining {
                VStack(spacing: 8) {
                    Text("\(days) días quedan")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if let week = viewModel.pregnancyWeek {
                        Text("Estás en la semana \(week)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    if let size = viewModel.babySizeString {
                        Text("El bebé es del tamaño de:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        Text(size)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.tint)
                    }
                }
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
