import SwiftUI

struct ReportDetailView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel = ReportDetailViewModel()

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "신고하기",
                    onBack: { container.navigationRouter.pop() },
                    rightButton: .none
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        cautionBox
                        groupSection
                        memberSection
                        reasonSection
                        contentSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()
                submitButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var cautionBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 1, green: 0.42, blue: 0.42))
                Text(viewModel.cautionTitle)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey700"))
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Divider().overlay(Color("grey200"))
            }

            Text(viewModel.cautionMessage)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color(red: 1, green: 0.30, blue: 0.30))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1, green: 0.95, blue: 0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 1, green: 0.73, blue: 0.73), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var groupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.groupSectionTitle)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))

            selectorField(
                text: viewModel.groupFieldText,
                isSelected: viewModel.isGroupSelected,
                isExpanded: viewModel.isGroupListExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.toggleGroupList()
                }
            }

            if viewModel.isGroupListExpanded {
                dropdownCard {
                    Text("내 그룹")
                        .pretendardText(size: 11, weight: .regular)
                        .foregroundColor(Color("grey400"))
                    ForEach(viewModel.myGroups) { group in
                        dropdownRow(group.displayTitle) {
                            viewModel.selectGroup(group)
                        }
                    }
                    Divider().overlay(Color("grey100"))
                    Text("참여 그룹")
                        .pretendardText(size: 11, weight: .regular)
                        .foregroundColor(Color("grey400"))
                    ForEach(viewModel.joinedGroups) { group in
                        dropdownRow(group.displayTitle) {
                            viewModel.selectGroup(group)
                        }
                    }
                }
            }
        }
    }

    private var memberSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.memberSectionTitle)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))

            selectorField(
                text: viewModel.memberFieldText,
                isSelected: viewModel.isMemberSelected,
                isExpanded: viewModel.isMemberListExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.toggleMemberList()
                }
            }

            if viewModel.isMemberListExpanded {
                dropdownCard {
                    Text(viewModel.selectedGroup?.displayTitle ?? "")
                        .pretendardText(size: 11, weight: .regular)
                        .foregroundColor(Color("grey400"))
                    ForEach(viewModel.membersForSelectedGroup) { member in
                        dropdownRow(member.name) {
                            viewModel.selectMember(member)
                        }
                    }
                }
            }
        }
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.reasonSectionTitle)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))

            ForEach(ReportReason.allCases, id: \.self) { reason in
                Button {
                    viewModel.selectReason(reason)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(viewModel.selectedReason == reason ? Color(red: 1, green: 0.79, blue: 0.64) : Color("grey200"))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(viewModel.selectedReason == reason ? Color("main200") : .white)
                            )

                        Text(reason.displayText)
                            .pretendardText(size: 15, weight: .regular)
                            .foregroundColor(viewModel.selectedReason == reason ? Color("main200") : Color("grey900"))

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(viewModel.selectedReason == reason ? Color(red: 1, green: 0.92, blue: 0.86) : Color("white"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.selectedReason == reason ? Color("main200") : Color("grey200"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.contentSectionTitle)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))

            ZStack(alignment: .topLeading) {
                if viewModel.content.isEmpty {
                    Text(viewModel.contentPlaceholder)
                        .pretendardText(size: 15, weight: .regular)
                        .foregroundColor(Color("grey500"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.content)
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(Color("grey800"))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .onChange(of: viewModel.content) { text in
                        viewModel.updateContent(text)
                    }
            }
            .frame(height: 200)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(viewModel.content.isEmpty ? Color("grey200") : Color("grey300"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack {
                Spacer()
                Text("\(viewModel.content.count) / \(ReportDetailViewModel.maxContentLength)")
                    .pretendardText(size: 12, weight: .regular)
                    .foregroundColor(Color("grey500"))
            }
        }
    }

    private var submitButton: some View {
        Button {
            guard let draft = viewModel.makeDraftForSubmit() else { return }
            ReportLocalStore.shared.submit(
                groupTitle: draft.groupTitle,
                reason: draft.reason,
                content: draft.content
            )
            container.navigationRouter.pop()
        } label: {
            Text("신고 전송")
                .pretendardText(size: 18, weight: viewModel.canSubmit ? .medium : .regular)
                .foregroundColor(viewModel.canSubmit ? .white : Color("grey500"))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(viewModel.canSubmit ? Color("grey900") : Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func selectorField(
        text: String,
        isSelected: Bool,
        isExpanded: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(isSelected ? Color("grey900") : Color("grey500"))
                    .lineLimit(1)
                Spacer()
                Circle()
                    .fill(isSelected || isExpanded ? Color(red: 1, green: 0.92, blue: 0.86) : Color("grey100"))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSelected || isExpanded ? Color("main200") : Color("grey400"))
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    )
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .frame(height: 48)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("grey300") : Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func dropdownCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.vertical, 4)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    private func dropdownRow(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey700"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReportDetailView()
        .environmentObject(DIContainer())
}
