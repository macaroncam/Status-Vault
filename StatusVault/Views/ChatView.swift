import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.timestamp, order: .forward) private var allMessages: [ChatMessage]
    @Query private var documents: [Document]

    @State private var messageText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedProvider: AIProvider = .openAI

    private var conversationMessages: [ChatMessage] {
        allMessages.filter { $0.conversationID == "default" }
    }

    private var chatService: ChatService {
        switch selectedProvider {
        case .openAI:
            return OpenAIChatService()
        case .anthropic:
            return AnthropicChatService()
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if conversationMessages.isEmpty {
                                EmptyChatView()
                            } else {
                                ForEach(conversationMessages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }

                            if isLoading {
                                TypingIndicator()
                            }

                            if let error = errorMessage {
                                ErrorMessageView(message: error)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: conversationMessages.count) { _, _ in
                        if let lastMessage = conversationMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Area
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Ask about immigration, travel, documents...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                        )
                        .lineLimit(1...5)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Immigration Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("AI Provider", selection: $selectedProvider) {
                            ForEach(AIProvider.allCases) { provider in
                                Label(provider.rawValue, systemImage: provider.icon)
                                    .tag(provider)
                            }
                        }

                        Divider()

                        Button(action: clearChat) {
                            Label("Clear Chat", systemImage: "trash")
                        }

                        NavigationLink(destination: APISettingsView()) {
                            Label("API Settings", systemImage: "key.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        // Clear input and error
        messageText = ""
        errorMessage = nil

        // Save user message
        let userChatMessage = ChatMessage(role: .user, content: userMessage, conversationID: "default")
        modelContext.insert(userChatMessage)

        isLoading = true

        Task {
            do {
                // Build document context
                let documentContext = DocumentContextBuilder.shared.buildContext(from: Array(documents))

                // Get response from AI
                let response = try await chatService.sendMessage(
                    userMessage,
                    conversationHistory: conversationMessages,
                    documentContext: documentContext
                )

                // Save assistant response
                await MainActor.run {
                    let assistantMessage = ChatMessage(role: .assistant, content: response, conversationID: "default")
                    modelContext.insert(assistantMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func clearChat() {
        for message in conversationMessages {
            modelContext.delete(message)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user ?
                                  LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  ) : LinearGradient(
                                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                            )
                    )

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            animating = true
        }
    }
}

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }

            Text("Immigration Assistant")
                .font(.title2)
                .fontWeight(.bold)

            Text("Ask me anything about immigration, travel, visa requirements, or your documents")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                Text("Example questions:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SampleQuestionView(icon: "airplane", question: "Can I travel to Mexico?")
                SampleQuestionView(icon: "doc.text", question: "What documents do I need for OPT?")
                SampleQuestionView(icon: "calendar", question: "When does my work authorization expire?")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.vertical, 60)
    }
}

struct SampleQuestionView: View {
    let icon: String
    let question: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            Text(question)
                .font(.subheadline)
        }
    }
}

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic Claude"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .openAI: return "brain"
        case .anthropic: return "sparkles"
        }
    }
}

struct APISettingsView: View {
    @State private var openAIKey = ChatConfiguration.shared.openAIAPIKey ?? ""
    @State private var anthropicKey = ChatConfiguration.shared.anthropicAPIKey ?? ""
    @State private var showingSaved = false

    var body: some View {
        Form {
            Section {
                Text("Configure your AI provider API keys to enable the immigration assistant chatbot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("OpenAI") {
                SecureField("API Key", text: $openAIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
            }

            Section("Anthropic Claude") {
                SecureField("API Key", text: $anthropicKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Link("Get API Key", destination: URL(string: "https://console.anthropic.com/")!)
                    .font(.caption)
            }

            Section {
                Button(action: saveKeys) {
                    HStack {
                        Spacer()
                        if showingSaved {
                            Label("Saved!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("Save API Keys")
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("API Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveKeys() {
        ChatConfiguration.shared.openAIAPIKey = openAIKey.isEmpty ? nil : openAIKey
        ChatConfiguration.shared.anthropicAPIKey = anthropicKey.isEmpty ? nil : anthropicKey

        showingSaved = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaved = false
        }
    }
}
