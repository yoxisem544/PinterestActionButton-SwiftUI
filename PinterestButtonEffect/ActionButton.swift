//
//  ActionButton.swift
//  PinterestButtonEffect
//
//  Created by David on 2023/10/2.
//

import SwiftUI

struct ActionButton: View {

    enum ActionType: CaseIterable {
        case pin
        case share
        case cross
        case more

        var imageName: String {
            switch self {
            case .pin: return "pin.fill"
            case .share: return "square.and.arrow.up"
            case .cross: return "xmark"
            case .more: return "ellipsis"
            }
        }
    }

    let actionType: ActionType
    let isFocus: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isFocus ? Color(hex: 0xc33532) : Color.white)

            Image(systemName: actionType.imageName)
                .renderingMode(.template)
                .fontWeight(.medium)
                .foregroundStyle(isFocus ? Color.white : Color(hex: 0x636064))
        }
        .frame(width: 50, height: 50)
    }
}

private struct Container: View {
    var body: some View {
        HStack {
            ActionButton(actionType: .pin, isFocus: true)
            ActionButton(actionType: .share, isFocus: false)
            ActionButton(actionType: .cross, isFocus: false)
            ActionButton(actionType: .more, isFocus: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray)
    }
}

#Preview {
    Container()
}
