//
//  DiscoverView.swift
//  Applite
//
//  Created by Milán Várady on 2022. 10. 14..
//

import SwiftUI

/// Shows apps in categories
struct DiscoverView: View {
    @EnvironmentObject var caskManager: CaskManager
    @Binding var navigationSelection: SidebarItem
    @State var currentPage: Float = 0

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                // MARK: - Hero Banner
                HerobannerView()
                    .padding(.bottom, 8)

                Text("Discover", comment: "Discover view title")
                    .font(.appliteLargeTitle)
                    .padding(.bottom)

                ForEach(caskManager.categories) { category in
                    DiscoverSectionView(category: category, navigationSelection: $navigationSelection)

                    Divider()
                        .padding(.vertical, 20)
                }
            }
            .padding()
        }

    }
}

// MARK: - Hero Banner
private struct HerobannerView: View {
    var body: some View {
        HStack(spacing: 20) {
            Image("AppliteIcon")
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("LegitApp")
                    .font(.system(size: 22, weight: .bold))

                Text("Quản lý ứng dụng macOS dễ dàng", comment: "Hero banner subtitle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 4)
        .padding(.bottom, 4)
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(navigationSelection: .constant(.home))
            .environmentObject(CaskManager())
    }
}
