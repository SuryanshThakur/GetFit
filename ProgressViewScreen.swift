import SwiftUI
import Charts

struct ProgressEntry: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let waist: Double
    let hips: Double
    let chest: Double
    let arms: Double
    let hydrationMl: Int
    let sleepHours: Double
    let photo: UIImage?
}

struct ProgressViewScreen: View {
    @State private var todayWeight: Double = 68.0
    @State private var todayWaist: Double = 80.0
    @State private var todayHips: Double = 92.0
    @State private var todayChest: Double = 95.0
    @State private var todayArms: Double = 30.0
    @State private var todayHydrationMl: Int = 1500
    @State private var todaySleepHours: Double = 7.0
    @State private var todayPhoto: UIImage? = nil
    @State private var showImagePicker = false
    @State private var segment: String = "Weight"
    @State private var entries: [ProgressEntry] = [
        // Demo data
        ProgressEntry(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, weight: 68.5, waist: 81, hips: 93, chest: 95, arms: 30, hydrationMl: 1750, sleepHours: 7.5, photo: nil),
        ProgressEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, weight: 68.2, waist: 80.5, hips: 92.8, chest: 95, arms: 30, hydrationMl: 1600, sleepHours: 7, photo: nil),
        ProgressEntry(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, weight: 68.0, waist: 80, hips: 92.5, chest: 94.8, arms: 29.8, hydrationMl: 1700, sleepHours: 7, photo: nil),
        ProgressEntry(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, weight: 67.8, waist: 79.8, hips: 92, chest: 94.5, arms: 29.7, hydrationMl: 1800, sleepHours: 7.2, photo: nil),
        ProgressEntry(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, weight: 67.6, waist: 79.5, hips: 91.8, chest: 94.5, arms: 29.6, hydrationMl: 1650, sleepHours: 7.5, photo: nil),
        ProgressEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, weight: 67.4, waist: 79.2, hips: 91.5, chest: 94.2, arms: 29.5, hydrationMl: 1550, sleepHours: 8, photo: nil)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Log Today's Progress")
                    .font(.title2).bold()
                Form {
                    Section(header: Text("Body Weight (kg)")) {
                        HStack {
                            TextField("Weight", value: $todayWeight, formatter: numberFormatter)
                                .keyboardType(.decimalPad)
                            Spacer()
                            Button("Save") {
                                addEntry()
                            }
                        }
                    }
                    Section(header: Text("Measurements (cm)")) {
                        HStack { Text("Waist"); Spacer(); TextField("Waist", value: $todayWaist, formatter: numberFormatter).keyboardType(.decimalPad).frame(width: 60) }
                        HStack { Text("Hips"); Spacer(); TextField("Hips", value: $todayHips, formatter: numberFormatter).keyboardType(.decimalPad).frame(width: 60) }
                        HStack { Text("Chest"); Spacer(); TextField("Chest", value: $todayChest, formatter: numberFormatter).keyboardType(.decimalPad).frame(width: 60) }
                        HStack { Text("Arms"); Spacer(); TextField("Arms", value: $todayArms, formatter: numberFormatter).keyboardType(.decimalPad).frame(width: 60) }
                    }
                    Section(header: Text("Hydration (L)")) {
                        HStack {
                            Text(String(format: "%.1f L", Double(todayHydrationMl)/1000))
                            Spacer()
                            Button(action: { todayHydrationMl = max(0, todayHydrationMl - 250) }) {
                                Image(systemName: "minus.circle.fill").foregroundColor(.blue)
                            }
                            Button(action: { todayHydrationMl += 250 }) {
                                Image(systemName: "plus.circle.fill").foregroundColor(.blue)
                            }
                        }
                    }
                    Section(header: Text("Sleep Duration (hours)")) {
                        HStack {
                            Stepper(value: $todaySleepHours, in: 0...12, step: 0.25) {
                                Text(String(format: "%.2f", todaySleepHours))
                            }
                        }
                    }
                    Section(header: Text("Progress Photo")) {
                        HStack {
                            if let img = todayPhoto {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            Button("Add Progress Photo") {
                                showImagePicker = true
                            }
                        }
                    }
                }
                .frame(height: 500)


            }
            .padding()
        }
        .navigationTitle("Progress Tracker")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $todayPhoto)
        }
    }

    func addEntry() {
        let newEntry = ProgressEntry(
            date: Date(),
            weight: todayWeight,
            waist: todayWaist,
            hips: todayHips,
            chest: todayChest,
            arms: todayArms,
            hydrationMl: todayHydrationMl,
            sleepHours: todaySleepHours,
            photo: todayPhoto
        )
        entries.append(newEntry)
    }

    var numberFormatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 2
        return nf
    }
}

// Basic ImagePicker compatible with SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = img
            }
            picker.dismiss(animated: true)
        }
    }
}

struct ProgressViewScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { ProgressViewScreen() }
    }
}
