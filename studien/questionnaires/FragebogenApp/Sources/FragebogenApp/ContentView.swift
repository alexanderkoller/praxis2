import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) var store

    var body: some View {
        TabView {
            Tab("Fragebögen", systemImage: "doc.text.fill") {
                FrageboegenTab()
            }
            Tab("Patient", systemImage: "person.fill") {
                PatientInfoView()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct PatientInfoView: View {
    @Environment(AppStore.self) var store

    var body: some View {
        Form {
            Section("Patientendaten") {
                LabeledContent("Name", value: store.patient.name)
                LabeledContent("Geburtsdatum", value: store.patient.geburtsdatum)
            }
        }
        .formStyle(.grouped)
    }
}
