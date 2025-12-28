//
//  CreditsView.swift
//  SwiftAA
//
//  Created by Kihron on 2/19/24.
//

import CachedAsyncImage
import SwiftUI

struct CreditsView: View {
    @State var showLogUploadedAlert = false
    @State var logUploadedAlert: String? = nil
    @State var logLink: String? = nil
    @State var supporters: [Supporter] = []
    var body: some View {
        SettingsPageView(title: "Credits & Help") {
            SettingsCardView {
                VStack {
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
                        CreditsEntryView(
                            name: "Slackow", role: "Developer", icon: "wrench.adjustable.fill",
                            color: .teal)

                        CreditsEntryView(
                            name: "Kihron", role: "Developer", icon: "wrench.adjustable.fill",
                            color: .orange)

                        CreditsEntryView(
                            name: "nealxm", uuid: "9ae165d08b204c38916bee10414279e0",
                            role: "Beta Tester", icon: "atom", color: .green)

                    }
                    Divider()
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
                        ForEach(self.supporters, id: \.uuid) { supporter in
                            CreditsEntryView(
                                name: supporter.name, uuid: supporter.uuid, role: "Supporter",
                                icon: "heart.fill", color: .pink)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .task {
                    // preload from file system
                    await fetchSupporters(supplier: supportersFromFile)
                    // load from GitHub
                    Task {
                        await fetchSupporters(supplier: supportersFromOnline)
                    }
                }
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
                            "For setting up the wall _without_ SeedQueue, read the [setup guide](https://github.com/Slackow/SlackowWall/blob/main/Info/guide.md)"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    HStack {
                        Image(systemName: "arrow.up.document.fill")
                            .font(.title)
                            .foregroundStyle(.gray)
                            .frame(width: 30)
                        HStack(spacing: 0) {
                            Text("To upload the current log and send it to someone, click ")
                            Text(.init("here").blue())
                        }
                        .onTapGesture {
                            LogManager.shared.uploadLog { message, url in
                                logLink = url
                                logUploadedAlert = message
                                showLogUploadedAlert = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .alert(
                        "Log File Upload", isPresented: $showLogUploadedAlert,
                        presenting: logUploadedAlert
                    ) { _ in
                        if let logLink {
                            Button("Copy Link") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(logLink, forType: .string)
                            }
                        }
                        Button("Close") {}
                    } message: { _ in
                        Text(logUploadedAlert ?? "Unable to upload.")
                    }
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

    private func fetchSupporters(supplier: () async -> String?) async {
        var supporters: [Supporter] = []
        // preload from file
        // get from internet
        if let donationsTxt = await supplier() {
            donationsTxt.split(whereSeparator: \.isNewline).forEach { line in
                let splitLine = line.split(separator: ",", maxSplits: 2)
                if splitLine.count == 2 {
                    supporters.append(
                        Supporter(name: String(splitLine[0]), uuid: String(splitLine[1])))
                }
            }
            self.supporters = supporters
        }
    }

    private func supportersFromOnline() async -> String? {
        guard
            let url = URL(
                string: "https://raw.githubusercontent.com/Slackow/SlackowWall/main/donations.txt")
        else { return nil }
        let request = URLRequest(
            url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 60)
        guard let (data, _) = try? await URLSession.shared.data(for: request),
            let donationsTxt = String(data: data, encoding: .utf8)
        else { return nil }
        writeSupportersToFile(supporters: donationsTxt)
        return donationsTxt
    }

    private func supportersFromFile() -> String? {
        return try? String(
            contentsOfFile: "~/Library/Application Support/SlackowWall/donations.txt",
            encoding: .utf8)
    }

    private func writeSupportersToFile(supporters: String) {
        guard !supporters.isEmpty else { return }
        try? supporters.write(
            toFile: "~/Library/Application Support/SlackowWall/donations.txt", atomically: true,
            encoding: .utf8)
    }
}

struct Supporter: Codable {
    let name: String
    let uuid: String
}

extension AttributedString {
    fileprivate func blue() -> Self {
        return self.settingAttributes(AttributeContainer().foregroundColor(.systemBlue))
    }
}

#Preview {
    CreditsView()
}
