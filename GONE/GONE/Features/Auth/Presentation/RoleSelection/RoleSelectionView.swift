//
//  RoleSelectionView.swift
//  GONE
//

import SwiftUI

struct RoleSelectionView: View {
    let onRoleSelected: (AccountRole) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("GONELogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 24)
                .accessibilityLabel("GONE")
                .padding(.top, 34)

            VStack(alignment: .leading, spacing: GONESpacing.small) {
                Text("편리한 학교생활의 시작")
                    .font(GONEFont.sfPro(size: 22, weight: .bold))
                    .foregroundStyle(Color.goneTextPrimary)

                Text("학생 또는 선생님으로 로그인하고\n필요한 학교 서비스를 간편하게 이용해보세요.")
                    .font(GONEFont.sfPro(size: 15))
                    .foregroundStyle(Color.goneTextSecondary)
                    .lineSpacing(4)
            }
            .padding(.top, 42)

            Spacer(minLength: 32)

            Image("RoleSelectionIllustration")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            Spacer(minLength: 32)

            VStack(spacing: GONESpacing.medium) {
                GONEPrimaryButton(
                    title: "학생 로그인",
                    isEnabled: true,
                    isLoading: false,
                    action: { onRoleSelected(.student) }
                )
                .accessibilityHint("학생 로그인 화면으로 이동합니다.")

                Button(action: { onRoleSelected(.teacher) }) {
                    Text("선생님 로그인")
                        .font(GONEFont.sfPro(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .foregroundStyle(Color.goneBrandPrimary)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: GONECornerRadius.button, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: GONECornerRadius.button, style: .continuous)
                        .stroke(Color.goneBrandPrimary, lineWidth: 1)
                }
                .accessibilityLabel("선생님 로그인")
                .accessibilityHint("선생님 로그인 화면으로 이동합니다.")
            }
            .padding(.bottom, GONESpacing.large)
        }
        .padding(.horizontal, GONESpacing.screenHorizontal)
        .background(Color(.systemBackground))
    }
}

#Preview {
    RoleSelectionView(onRoleSelected: { _ in })
}
