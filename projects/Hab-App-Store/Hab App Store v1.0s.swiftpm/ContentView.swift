import SwiftUI
import UIKit

// MARK: - Models

struct ProjectResponse: Codable {
    let projects: [String]
}

struct Project: Identifiable {
    var id: String { name } 
    let name: String
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Model
class StoreViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var errorMessage: String?
    @Published var isDownloading = false
    @Published var downloadedFileURL: URL?
    
    func fetchProjects() {
        guard let url = URL(string: "https://bestytbersever-boopgithubio-production.up.railway.app/projects.json") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ProjectResponse.self, from: data)
                    let projectObjects = decodedResponse.projects.map { Project(name: $0) }
                    
                    DispatchQueue.main.async {
                        self.projects = projectObjects
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
    
    func downloadProject(name: String) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://bestytbersever-boopgithubio-production.up.railway.app/download?project=\(encodedName)") else {
            return
        }
        
        DispatchQueue.main.async {
            self.isDownloading = true
            self.errorMessage = nil
        }
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            // 1. Check for network errors immediately on the background thread
            if let error = error {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let localURL = localURL else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.errorMessage = "Download failed: No file returned."
                }
                return
            }
            
            // 2. Safely move the file BEFORE this closure exits and iOS deletes it
            let fileManager = FileManager.default
            
            // Create a totally unique subdirectory for this specific download instance
            let uniqueDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let filename = response?.suggestedFilename ?? "\(name).zip"
            let destinationURL = uniqueDir.appendingPathComponent(filename)
            
            do {
                // Ensure our temporary subdirectory exists
                try fileManager.createDirectory(at: uniqueDir, withIntermediateDirectories: true, attributes: nil)
                
                // Move the file safely while it still exists at localURL
                try fileManager.moveItem(at: localURL, to: destinationURL)
                
                // 3. Jump back to the main thread ONLY to update the UI
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.downloadedFileURL = destinationURL
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.errorMessage = "Failed to save file: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Feedback View
struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackText = ""
    @State private var isSubmitting = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("What can we improve?")) {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if feedbackText.isEmpty {
                                    Text("Type your feedback here...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Button(action: sendFeedback) {
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Submit Feedback")
                                .bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .listRowBackground(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Feedback", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("Successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func sendFeedback() {
        // Replace spaces with underscores
        let underscoredText = feedbackText.replacingOccurrences(of: " ", with: "_")
        
        // URL-encode special characters safely
        guard let encodedText = underscoredText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            alertMessage = "Error processing text formatting."
            showAlert = true
            return
        }
        
        let urlString = "https://docs.google.com/forms/d/e/1FAIpQLSf5p5ou3bg52OCeQleniliaXi4N0joirQSm852Pv3pxY5VkAA/formResponse?usp=pp_url&entry.1130800782=\(encodedText)"
        
        guard let url = URL(string: urlString) else {
            alertMessage = "Invalid URL submission path."
            showAlert = true
            return
        }
        
        isSubmitting = true
        
        URLSession.shared.dataTask(with: url) { _, _, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    alertMessage = "Failed to send: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                alertMessage = "Successfully sent feedback! Thank you."
                showAlert = true
            }
        }.resume()
    }
}

// MARK: - UI Views
struct ContentView: View {
    @StateObject private var viewModel = StoreViewModel()
    @State private var showingErrorAlert = false
    
    // ADDED: State variable required to present the Feedback Sheet
    @State private var showingFeedbackSheet = false
    
    var body: some View {
        NavigationView {
            List(viewModel.projects) { project in
                HStack {
                    Text(project.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.downloadProject(name: project.name)
                    }) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("App Store")
            .onAppear {
                viewModel.fetchProjects()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFeedbackSheet = true }) {
                        Image(systemName: "text.bubble")
                    }
                }
            }
            // Sheet for Feedback
            .sheet(isPresented: $showingFeedbackSheet) {
                FeedbackView()
            }
            // Sheet for Download Share
            .sheet(isPresented: Binding(
                get: { viewModel.downloadedFileURL != nil },
                set: { isPresented in
                    if !isPresented { viewModel.downloadedFileURL = nil }
                }
            )) {
                if let fileURL = viewModel.downloadedFileURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }
            .onChange(of: viewModel.errorMessage) { message in
                if message != nil {
                    showingErrorAlert = true
                }
            }
            .alert("Download Error", isPresented: $showingErrorAlert, presenting: viewModel.errorMessage) { _ in
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
            .overlay {
                if viewModel.isDownloading {
                    ProgressView("Downloading...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
