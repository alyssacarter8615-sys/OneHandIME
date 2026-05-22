#if os(macOS)
import Cocoa
import SwiftUI
import OneHandEngine

class CandidatePanel: NSPanel {
    static let shared = CandidatePanel()

    private let hostingView: NSHostingView<CandidateView>
    private let viewModel = CandidateViewModel()

    private init() {
        hostingView = NSHostingView(rootView: CandidateView(viewModel: viewModel))
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        contentView = hostingView
        hasShadow = true
    }

    func update(candidates: [Candidate], mode: Mode, page: Int, totalPages: Int) {
        viewModel.candidates = candidates
        viewModel.mode = mode
        viewModel.page = page
        viewModel.totalPages = totalPages
        hostingView.rootView = CandidateView(viewModel: viewModel)

        if candidates.isEmpty {
            orderOut(nil)
        } else {
            orderFront(nil)
        }
    }

    func showNear(_ point: NSPoint) {
        setFrameTopLeftPoint(point)
    }
}

class CandidateViewModel: ObservableObject {
    @Published var candidates: [Candidate] = []
    @Published var mode: Mode = .disambiguation
    @Published var page: Int = 0
    @Published var totalPages: Int = 0
}

struct CandidateView: View {
    @ObservedObject var viewModel: CandidateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(viewModel.candidates.enumerated()), id: \.offset) { idx, candidate in
                HStack {
                    Text("\(idx + 1).")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(candidate.word)
                        .font(.system(size: 14))
                }
            }
            if viewModel.totalPages > 1 {
                HStack {
                    Spacer()
                    Text("\(viewModel.page + 1)/\(viewModel.totalPages)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .windowBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
    }
}
#endif
