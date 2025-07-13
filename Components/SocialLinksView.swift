import SwiftUI

struct SocialLinksView: View {
    let socialLinks: SocialLinks
    
    var body: some View {
        HStack(spacing: 20) {
            if !socialLinks.instagram.isEmpty {
                BarSocialLinkButton(icon: "camera", title: "Instagram", url: socialLinks.instagram)
            }
            
            if !socialLinks.twitter.isEmpty {
                BarSocialLinkButton(icon: "bird", title: "Twitter", url: socialLinks.twitter)
            }
            
            if !socialLinks.facebook.isEmpty {
                BarSocialLinkButton(icon: "person.2", title: "Facebook", url: socialLinks.facebook)
            }
            
            if !socialLinks.website.isEmpty {
                BarSocialLinkButton(icon: "globe", title: "Website", url: socialLinks.website)
            }
        }
    }
}

struct BarSocialLinkButton: View {
    let icon: String
    let title: String
    let url: String
    
    var body: some View {
        Button(action: openURL) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openURL() {
        var urlString = url
        
        // Add protocol if missing
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        // Check if we can open the URL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("Failed to open URL: \(url)")
                }
            }
        } else {
            print("Cannot open URL: \(url)")
        }
    }
}
