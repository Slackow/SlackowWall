//
//  CreditsView.swift
//  SwiftAA
//
//  Created by Kihron on 2/19/24.
//

import CachedAsyncImage
import SwiftUI

struct CreditsView: View {
    var body: some View {
        SettingsPageView(title: "Credits") {
            SettingsCardView {
                VStack {
                    CreditsEntryView(
                        name: "Slackow", role: "Developer", icon: "wrench.adjustable.fill",
                        color: .teal)

                    CreditsEntryView(
                        name: "Kihron", role: "Developer", icon: "wrench.adjustable.fill",
                        color: .orange)

                    CreditsEntryView(
                        name: "nealxm", role: "Beta Tester", icon: "atom", color: .green)

                    CreditsEntryView(
                        name: "olock5", role: "Supporter", icon: "heart.fill", color: .pink)

                    CreditsEntryView(
                        name: "mukvl", role: "Supporter", icon: "heart.fill", color: .pink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            SettingsLabel(title: "Support Us")
                .padding(.top, 5)

            SettingsCardView {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundStyle(.pink)

                    Text(
                        "If you're finding SlackowWall helpful and would like to support its development, consider making a donation on our [Ko-fi](https://ko-fi.com/kscode)"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            SettingsLabel(title: "Need help?")
                .padding(.top, 5)

            SettingsCardView {
                VStack {
                    HStack {
                        Image(systemName: "wrench.adjustable.fill")
                            .font(.title)
                            .foregroundStyle(.gray)
                        Text(
                            "For help with technical issues, join the [Mac Speedrunning Discord](https://discord.gg/sczfsdE39W)"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                        Text(
                            "For help setting up BoatEye, try this [tutorial](https://www.youtube.com/watch?v=Mj42HbnPUZ4) by FlaxyBRuns"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    HStack {
                        Image(systemName: "text.document.fill")
                            .font(.title)
                            .foregroundStyle(.gray)
                            .frame(width: 30)
                        Text(
                            "For setting up the wall without SeedQueue, read the [setup guide](https://github.com/Slackow/SlackowWall/blob/main/Info/guide.md)"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var donationString: AttributedString {
        var attr = try! AttributedString(
            markdown:
                "If you’re finding SlackowWall helpful and would like to support its development, consider making a donation on our [Ko-fi](https://ko-fi.com/kscode)."
        )
        // iterate runs and underline only the link
        for run in attr.runs where run.link != nil {
            attr[run.range].underlineStyle = .single
        }
        return attr
    }

    private func getAvatarURL(_ name: String) -> URL? {
        return URL(string: "https://minotar.net/helm/\(name)/32")
    }
}

#Preview {
    CreditsView()
}
