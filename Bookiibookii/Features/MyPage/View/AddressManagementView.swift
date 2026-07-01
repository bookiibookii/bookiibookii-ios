import SwiftUI

struct AddressManagementView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: AddressManagementViewModel

    init(locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: AddressManagementViewModel(locationService: locationService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        tabBar
                        contentSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }

            addButton
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.selectedTab) { _, _ in
            Task { await viewModel.reloadCurrentTab() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.isDeliveryFormSheetPresented) {
            DeliveryAddressFormSheet(
                mode: viewModel.editingDelivery == nil ? .add : .edit,
                formState: $viewModel.deliveryFormState,
                isSearchPresented: $viewModel.showPostcode,
                isSaving: viewModel.isSaving,
                onCancel: { viewModel.closeDeliveryForm() },
                onSave: { Task { await viewModel.saveDeliveryForm() } },
                onSelectAddress: { viewModel.applyPostcode($0) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $viewModel.isExchangeFormSheetPresented) {
            ExchangeAddressFormSheet(
                mode: viewModel.editingExchange == nil ? .add : .edit,
                formState: $viewModel.exchangeFormState,
                isSearchPresented: $viewModel.showPlaceSearch,
                isSaving: viewModel.isSaving,
                onCancel: { viewModel.closeExchangeForm() },
                onSave: { Task { await viewModel.saveExchangeForm() } },
                onSelectPlace: { viewModel.applyExchangePostcode($0) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(20)
        }
        .alert("안내", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.alertMessage = nil }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { container.navigationRouter.pop() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("주소지 관리")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    // MARK: - Tabs

    private var tabBar: some View {
        HStack(spacing: 12) {
            tabButton(.delivery)
            tabButton(.exchange)
        }
    }

    private func tabButton(_ tab: AddressManagementTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            viewModel.selectedTab = tab
            viewModel.menuDeliveryId = nil
            viewModel.menuExchangeId = nil
        } label: {
            Text(tab.title)
                .pretendardText(size: 15, weight: .regular)
                .foregroundColor(isSelected ? Color("white") : Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Color("main200") : Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color("grey200"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.selectedTab {
        case .delivery:
            deliveryContent
        case .exchange:
            exchangeContent
        }
    }

    @ViewBuilder
    private var deliveryContent: some View {
        if viewModel.isLoading && viewModel.deliveries.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if viewModel.deliveries.isEmpty {
            emptyStateCard(
                title: viewModel.deliveryEmptyMessage.0,
                subtitle: viewModel.deliveryEmptyMessage.1
            )
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("배송지")
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                ForEach(viewModel.deliveries) { address in
                    deliveryCard(address)
                }
            }
        }
    }

    @ViewBuilder
    private var exchangeContent: some View {
        if viewModel.isLoading && viewModel.exchanges.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if viewModel.exchanges.isEmpty {
            emptyStateCard(
                title: viewModel.exchangeEmptyMessage.0,
                subtitle: viewModel.exchangeEmptyMessage.1
            )
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("교환 희망 장소")
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                ForEach(viewModel.exchanges) { address in
                    exchangeCard(address)
                }
            }
        }
    }

    private func emptyStateCard(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey600"))
            Text(subtitle)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey600"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func deliveryCard(_ address: DeliveryAddress) -> some View {
        ZStack(alignment: .topTrailing) {
            locationCardContent(
                isDefault: address.isDefault,
                placeName: address.placeName,
                address: address.address,
                addressDetail: address.addressDetail
            )

            meatballButton {
                viewModel.menuDeliveryId = viewModel.menuDeliveryId == address.id ? nil : address.id
                viewModel.menuExchangeId = nil
            }

            if viewModel.menuDeliveryId == address.id {
                overflowMenu(
                    onEdit: { viewModel.openEditDeliveryForm(for: address) },
                    onDelete: { Task { await viewModel.deleteDelivery(address) } }
                )
                .offset(x: -8, y: 40)
            }
        }
    }

    private func exchangeCard(_ address: ExchangeAddress) -> some View {
        ZStack(alignment: .topTrailing) {
            locationCardContent(
                isDefault: address.isDefault,
                placeName: address.placeName,
                address: address.address,
                addressDetail: address.addressDetail
            )

            meatballButton {
                viewModel.menuExchangeId = viewModel.menuExchangeId == address.id ? nil : address.id
                viewModel.menuDeliveryId = nil
            }

            if viewModel.menuExchangeId == address.id {
                overflowMenu(
                    onEdit: { viewModel.openEditExchangeForm(for: address) },
                    onDelete: { Task { await viewModel.deleteExchange(address) } }
                )
                .offset(x: -8, y: 40)
            }
        }
    }

    private func locationCardContent(
        isDefault: Bool,
        placeName: String,
        address: String,
        addressDetail: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if isDefault {
                    Text("대표")
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(Color("main200"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("main100"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(placeName)
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                Spacer(minLength: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(address)
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(Color("grey700"))
                if let detail = addressDetail, !detail.isEmpty {
                    Text(detail)
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey700"))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func meatballButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("ic_meetball")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func overflowMenu(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            menuRow(title: "수정하기", icon: "ic_edit", action: onEdit)
            menuRow(title: "삭제하기", icon: "ic_trash", action: onDelete)
        }
        .frame(width: 160)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func menuRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey700"))
                Spacer()
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var addButton: some View {
        Button(action: { viewModel.openAddForm() }) {
            Text("추가하기")
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(Color("white"))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Color("grey900"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
