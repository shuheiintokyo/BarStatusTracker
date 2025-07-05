import SwiftUI

struct SocialLinksView: View {
    let socialLinks: SocialLinks
    
    var body: some View {
        HStack(spacing: 20) {
            if !socialLinks.instagram.isEmpty {
                SocialLinkButton(icon: "camera", title: "Instagram", url: socialLinks.instagram)
            }
            
            if !socialLinks.twitter.isEmpty {
                SocialLinkButton(icon: "bird", title: "Twitter", url: socialLinks.twitter)
            }
            
            if !socialLinks.website.isEmpty {
                SocialLinkButton(icon: "globe", title: "Website", url: socialLinks.website)
            }
        }
    }
}

struct SocialLinkButton: View {
    let icon: String
    let title: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
}
