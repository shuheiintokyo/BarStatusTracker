import SwiftUI

struct SocialLinksView: View {
    let socialLinks: SocialLinks
    
    var body: some View {
        HStack(spacing: 20) {
            if !socialLinks.instagram.isEmpty {
                BarSocialLinkButton(icon: "instagram-icon", title: "Instagram", url: socialLinks.instagram, isAssetImage: true)
            }
            
            if !socialLinks.twitter.isEmpty {
                BarSocialLinkButton(icon: "x-icon", title: "X", url: socialLinks.twitter, isAssetImage: true)
            }
            
            if !socialLinks.facebook.isEmpty {
                BarSocialLinkButton(icon: "facebook-icon", title: "Facebook", url: socialLinks.facebook, isAssetImage: true)
            }
            
            if !socialLinks.website.isEmpty {
                BarSocialLinkButton(icon: "globe", title: "Website", url: socialLinks.website, isAssetImage: false)
            }
        }
    }
}

struct BarSocialLinkButton: View {
    let icon: String
    let title: String
    let url: String
    let isAssetImage: Bool
    
    var body: some View {
        Button(action: openURL) {
            VStack(spacing: 4) {
                // Use either asset image or system image based on isAssetImage flag
                if isAssetImage {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
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
