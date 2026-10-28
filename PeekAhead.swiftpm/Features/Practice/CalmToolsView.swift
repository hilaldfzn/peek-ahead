import SwiftUI

/// "Pick my calm tools": choose any number of tools. They are shown on the day's Now / Next strip as a reminder.
struct CalmToolsView: View {
    let tools: [CalmTool]
    let onDone: (Set<CalmTool>) -> Void

    @State private var chosen: Set<CalmTool>

    init(tools: [CalmTool], initiallyChosen: Set<CalmTool> = [], onDone: @escaping (Set<CalmTool>) -> Void) {
        self.tools = tools
        self.onDone = onDone
        _chosen = State(initialValue: initiallyChosen)
    }

    var body: some View {
        PracticeScaffold(
            title: "Pick my calm tools",
            instruction: Text("Pick what helps you. You can pick more than one.")
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: AppSpace.lg)], spacing: AppSpace.lg) {
                ForEach(tools) { tool in
                    ChoiceCard(
                        artwork: .bundle(tool.imageName),
                        title: Text(tool.title),
                        isSelected: chosen.contains(tool)
                    ) {
                        if chosen.contains(tool) { chosen.remove(tool) } else { chosen.insert(tool) }
                    }
                }
            }
        } buttons: {
            Button("Done") { onDone(chosen) }
                .buttonStyle(.childPrimary)
        }
    }
}
