

import SwiftUI
import CloudKit

struct SharerTestView: View {
    @State private var childName = ""
    @State private var kids: [KidRecord] = []
    @State private var selectedKid: KidRecord?
    @State private var isLoading = false
    @State private var feedbackMessage = ""
    @State private var sharingSheet: Bool = false
    @State private var shareView: AnyView?
    @State private var zoneReady = false
    
    private var cloudService: CloudService = .shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Kid Sharing Test")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading) {
                Text("Add a new child")
                    .font(.headline)
                
                TextField("Child name", text: $childName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)
                
                Button("Add Child") {
                    addChild()
                }
                .disabled(childName.isEmpty || isLoading || !zoneReady)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            if !kids.isEmpty {
                VStack(alignment: .leading) {
                    Text("Your Children")
                        .font(.headline)
                    
                    List(kids, id: \.id) { kid in
                        HStack {
                            Text(kid.name)
                            Spacer()
                            Button("Share") {
                                selectedKid = kid
                                shareKid(kid)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            if !feedbackMessage.isEmpty {
                Text(feedbackMessage)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            setupCloudKit()
        }
        .sheet(isPresented: $sharingSheet) {
            if let shareView = shareView {
                shareView
            } else {
                Text("Preparing sharing...")
            }
        }
    }
    
    private func setupCloudKit() {
        feedbackMessage = "Setting up CloudKit..."
        print("Setting up CloudKit...")
        
        Task {
            do {
                // Create the Kids zone once when the view appears
                try await cloudService.createZoneIfNeeded(zoneName: "Kids")
                print("✅ Kids zone created or verified")
                
                DispatchQueue.main.async {
                    zoneReady = true
                    feedbackMessage = "✅ CloudKit setup complete"
                    // Load kids after zone is ready
                    loadKids()
                }
            } catch {
                let errorMessage = "❌ Error setting up CloudKit: \(error.localizedDescription)"
                print(errorMessage)
                DispatchQueue.main.async {
                    feedbackMessage = errorMessage
                }
            }
        }
    }
    
    private func addChild() {
        guard !childName.isEmpty else { return }
        
        isLoading = true
        feedbackMessage = "Adding child to CloudKit..."
        
        let kid = KidRecord(name: childName)
        print("Attempting to add kid with name: \(kid.name)")
        
        // Check if record is created properly
        if kid.record == nil {
            DispatchQueue.main.async {
                isLoading = false
                feedbackMessage = "❌ Error: Failed to create kid record (record is nil)"
                print("Failed to create kid record - record is nil")
            }
            return
        }
        
        Task {
            do {
                print("Calling cloudService.createKid...")
                try await cloudService.createKid(kid) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        switch result {
                        case .success(let newKid):
                            print("✅ Successfully added \(newKid.name) to CloudKit")
                            feedbackMessage = "✅ Successfully added \(newKid.name) to CloudKit"
                            childName = ""
                            loadKids()
                        case .failure(let error):
                            print("❌ Error adding child: \(error)")
                            feedbackMessage = "❌ Error adding child: \(error)"
                        }
                    }
                }
            } catch {
                print("❌ Exception: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isLoading = false
                    feedbackMessage = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadKids() {
        isLoading = true
        feedbackMessage = "Loading your children from CloudKit..."
        print("Loading kids from CloudKit...")
        
        Task {
            do {
                try await cloudService.fetchKids { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        switch result {
                        case .success(let fetchedKids):
                            kids = fetchedKids
                            let message = fetchedKids.isEmpty
                                ? "No children found in CloudKit"
                                : "✅ Loaded \(fetchedKids.count) children"
                            feedbackMessage = message
                            print(message)
                        case .failure(let error):
                            let errorMessage = "❌ Error loading children: \(error)"
                            feedbackMessage = errorMessage
                            print(errorMessage)
                        }
                    }
                }
            } catch {
                let errorMessage = "❌ Error: \(error.localizedDescription)"
                print(errorMessage)
                DispatchQueue.main.async {
                    isLoading = false
                    feedbackMessage = errorMessage
                }
            }
        }
    }
    
    private func shareKid(_ kid: KidRecord) {
        isLoading = true
        feedbackMessage = "Generating sharing link for \(kid.name)..."
        print("Generating sharing link for \(kid.name)...")
        
        Task {
            do {
                try await cloudService.shareKid(kid) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        switch result {
                        case .success(let view):
                            shareView = AnyView(view)
                            feedbackMessage = "✅ Share sheet prepared for \(kid.name)"
                            print("✅ Share sheet prepared for \(kid.name)")
                            sharingSheet = true
                        case .failure(let error):
                            let errorMessage = "❌ Error sharing kid: \(error)"
                            feedbackMessage = errorMessage
                            print(errorMessage)
                        }
                    }
                }
            } catch {
                let errorMessage = "❌ Error: \(error.localizedDescription)"
                print(errorMessage)
                DispatchQueue.main.async {
                    isLoading = false
                    feedbackMessage = errorMessage
                }
            }
        }
    }
}
