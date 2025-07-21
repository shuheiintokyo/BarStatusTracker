@Published var currentToast: ToastMessage?
@Published var showingToast = false

private init() {}

func showToast(_ message: ToastMessage) {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
        currentToast = message
        showingToast = true
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + message.duration) {
        self.hideToast()
    }
}

func hideToast() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        showingToast = false
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        currentToast = nil
    }
}

// Convenience methods for common feedback types
func showSuccess(_ message: String) {
    showToast(ToastMessage(text: message, type: .success))
}

func showError(_ message: String) {
    showToast(ToastMessage(text: message, type: .error))
}

func showInfo(_ message: String) {
    showToast(ToastMessage(text: message, type: .info))
}

func showWarning(_ message: String) {
    showToast(ToastMessage(text: message, type: .warning))
}
