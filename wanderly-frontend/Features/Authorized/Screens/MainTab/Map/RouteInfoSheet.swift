//
//  RouteInfoSheet.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 10.05.2025.
//
import SwiftUI

struct RouteInfoSheet: View {
    let route: RouteDrawable
    @Binding var reorderedMarkers: [MarkerDto]
    var routeIndex: Int
    @Binding var hasEdited: Bool
    var onClose: () -> Void
    var onRegenerate: () async -> Void
    var onBranch: (_ fromMarker: Int) async -> Void
    
    @State private var showRegenerateConfirmation = false
    
    @State private var showBranchAlert = false
    @State private var branchStartIndex: Int? = nil
    
    @State var isLoading = false
    
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        VStack(spacing: 12) {
            // Top Bar
            ZStack {
                Text("Route \(routeIndex + 1)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Button {
                        withAnimation {
                            editMode?.wrappedValue = editMode?.wrappedValue == .active ? .inactive : .active
                        }
                    } label: {
                        Image(systemName: editMode?.wrappedValue == .active ? "checkmark" : "pencil")
                            .foregroundColor(.accentColor)
                    }
                    .disabled(isLoading)

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundColor(.accentColor)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider()
            
            Button("Regenerate") {
                showRegenerateConfirmation = true
            }
            .disabled(!hasEdited || isLoading)
            .buttonStyle(ProminentButtonStyle())
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\((route.totalDistance / 1000).formatted(.number.precision(.fractionLength(2)))) km")
                    .font(.body)
                    .bold()
                
                Text("\(formattedDuration(route.expectedTravelTime)) travel • \(formattedDuration(Double(route.route.avgStayingTime) * 60)) stay")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
            .padding(.horizontal)
            
            List {
                Section {
                    ForEach(reorderedMarkers.indices, id: \.self) { index in
                        let marker = reorderedMarkers[index]
                        
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(marker.name)
                                    .font(.body)
                                    .bold()
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Text("\(marker.formattedTag) • \(marker.rating.formatted(.number.precision(.fractionLength(2))))⭐️")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)

                                Text("\(formattedDuration(Double(marker.stayingTime ?? 0) * 60)) stay")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                showBranchAlert = true
                                branchStartIndex = index
                            } label: {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundColor(.accentColor)
                                    .padding(8)
                            }
                            .buttonStyle(.plain)
                            .help("Regenerate route from this marker")
                            .disabled(isLoading || index + 1 == reorderedMarkers.count)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        reorderedMarkers.remove(atOffsets: offsets)
                        hasEdited = true
                    }
                    .onMove { indices, newOffset in
                        reorderedMarkers.move(fromOffsets: indices, toOffset: newOffset)
                        hasEdited = true
                    }
                }
            }
            .listStyle(.plain)
//            .environment(\.editMode, .constant(.active))
            .padding(.top, 4)
            
        }
        .background(Color.white.ignoresSafeArea())
        .alert("Regenerate this route?", isPresented: $showRegenerateConfirmation) {
            Button("Regenerate", role: .destructive) {
                Task {
                    isLoading = true
                    await onRegenerate()
                    isLoading = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Regenerating this route will erase your current progress. Are you sure?")
        }
        
        .alert("Branch from this marker?", isPresented: $showBranchAlert) {
            Button("Branch", role: .destructive) {
                if let index = branchStartIndex {
                    Task {
                        isLoading = true
                        await onBranch(index)
                        isLoading = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You're about to regenerate this route starting from this marker. Earlier markers will remain, but all later ones will be changed. Your progress will be erased. Are you sure?")
        }
    }
    
    func formattedDuration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: seconds) ?? ""
    }
}
