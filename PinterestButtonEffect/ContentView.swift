//
//  ContentView.swift
//  PinterestButtonEffect
//
//  Created by David on 2023/10/2.
//

import SwiftUI

struct ContentView: View {

    @State private var focusedAction: ActionButton.ActionType?
    @State private var aboutToFocusedAction: ActionButton.ActionType?
    @State private var extendOffsetRatios: [CGFloat] = Array(repeating: 1.0, 
                                                             count: Self.actionButtonTypes.count)
    @State private var isScaleInfo: [Bool] = Array(repeating: false,
                                                count: Self.actionButtonTypes.count)

    private static let actionButtonTypes = ActionButton.ActionType.allCases
    private let gapAngle: CGFloat = 30

    private var buttons: [(Int, ActionButton.ActionType)] {
        Array(zip(Self.actionButtonTypes.indices, Self.actionButtonTypes))
    }

    var body: some View {
        ZStack {
            Group {
                ForEach(buttons, id: \.0) { index, button in
                    ActionButton(actionType: button, isFocus: focusedAction == button)
                        .offset(
                            x: x(of: angle(of: index)) * extendOffsetRatios[index],
                            y: y(of: angle(of: index)) * extendOffsetRatios[index]
                        )
                        .scaleEffect(isScaleInfo[index] ? 1.15 : 1.0)
                }
            }
            .opacity(didStartPopupAction ? 1 : 0)

            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .gesture(longPress.sequenced(before: pressing))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.yellow)
        .padding()
    }

    private func angle(of index: Int) -> CGFloat {
        gapAngle * CGFloat(index)
    }

    // MARK: - Radian Calculation

    private var popDistance: CGFloat {
        didStartPopupAction ? 104 : 0
    }

    private func radian(of degree: CGFloat) -> Double {
        let d = degree - 180
        let r = d * Double.pi / 180.0
        return r
    }

    private func x(of degree: Double) -> Double {
        let r = radian(of: degree)
        return popDistance * cos(r)
    }

    private func y(of degree: Double) -> Double {
        let r = radian(of: degree)
        return popDistance * sin(r)
    }

    // MARK: - Gesture

    @State var didStartPopupAction = false
    @State var startLocation: CGPoint? = nil

    @GestureState private var isDetectingLongPress = false
    private var longPress: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .updating($isDetectingLongPress, body: { currentState, gestureState, transaction in
                gestureState = currentState
            })
            .onEnded { finished in
                withAnimation(.bouncy(duration: 0.36, extraBounce: 0.12)) {
                    didStartPopupAction = true
                }
            }
    }

    @State private var offset: CGSize = .zero
    private var pressing: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if startLocation == nil {
                    startLocation = gesture.startLocation
                }
                updateOffset(gesture.translation)
            }
            .onEnded { _ in
                if let index = index(of: focusedAction) {
                    let type = Self.actionButtonTypes[index]
                    print("Done", index, type)
                }

                offset = .zero
                startLocation = nil
                resetStates()

                withAnimation(.bouncy(duration: 0.3, extraBounce: 0.1)) {
                    didStartPopupAction = false
                }
            }
    }

    private func updateOffset(_ value: CGSize) {
        guard let startLocation else { return }

        offset = value
        let (x1, y1) = (startLocation.x, startLocation.y) // A
        let (x2, y2) = (x1 + offset.width, y1 + offset.height) // B
        let (x3, y3): (CGFloat, CGFloat) = (25, 25) // C
        // 余弦定理，好像不需要
//        let AB = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
//        let AC = sqrt((x3 - x1) * (x3 - x1) + (y3 - y1) * (y3 - y1))
//        let COS_BAC = ((x2 - x1) * (x3 - x1) + (y2 - y1) * (y3 - y1)) / (AB * AC)
//        let BC = sqrt(AB * AB + AC * AC - 2 * AB * AC * COS_BAC)

        let threshold: CGFloat = 70
        let dragPoint = CGPoint(x: x2, y: y2)
        let origin = CGPoint(x: x3, y: y3)
        udpateFocusAction(dragPoint: dragPoint, origin: origin, threshold: threshold)
    }

    private func angle(dragPoint: CGPoint, origin: CGPoint) -> CGFloat {
        let dx = dragPoint.x - origin.x
        let dy = dragPoint.y - origin.y
        let r = atan2(dx, dy)
        // 270 反轉 y 軸
        let angle = (r * 180 / .pi + 360 + 270).truncatingRemainder(dividingBy: 360)

        return angle
    }

    private func distanceBetween(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
    }

    private func udpateFocusAction(dragPoint: CGPoint, origin: CGPoint, threshold: CGFloat) {
        let angle = angle(dragPoint: dragPoint, origin: origin)

        let diff = gapAngle / 2
        func range(of degree: CGFloat) -> ClosedRange<CGFloat> {
            return (degree - diff)...(degree + diff)
        }

        let distance = distanceBetween(dragPoint, origin)
        let possibleAction: ActionButton.ActionType?
        switch angle {
        case range(of: 90):
            possibleAction = .more
        case range(of: 90 + gapAngle):
            possibleAction = .cross
        case range(of: 90 + gapAngle * 2):
            possibleAction = .share
        case range(of: 90 + gapAngle * 3):
            possibleAction = .pin
        default:
            possibleAction = nil
        }

        let moveRatio = 0.05
        let extendRatio: CGFloat
        if distance >= threshold {
            focusedAction = possibleAction
            aboutToFocusedAction = possibleAction
            extendRatio = 1.0
        } else {
            focusedAction = nil
            aboutToFocusedAction = possibleAction

            let progress = 1 - (threshold - distance) / threshold
            extendRatio = 1.0 + moveRatio * progress
        }

        withAnimation {
            resetExtendOffsetRatios()
            setRatio(of: possibleAction, value: extendRatio)
            setScale(of: focusedAction)
        }
    }

    private func index(of type: ActionButton.ActionType?) -> Int? {
        switch type {
        case .pin: return 0
        case .share: return 1
        case .cross: return 2
        case .more: return 3
        default: return nil
        }
    }

    private func setRatio(of type: ActionButton.ActionType?, value: CGFloat) {
        if let index = index(of: type) {
            extendOffsetRatios[index] = value
        }
    }

    private func setScale(of type: ActionButton.ActionType?) {
        if let index = index(of: type) {
            isScaleInfo[index] = true
        }
    }

    private func resetExtendOffsetRatios() {
        extendOffsetRatios = Array(repeating: 1.0, count: Self.actionButtonTypes.count)
        isScaleInfo = Array(repeating: false, count: Self.actionButtonTypes.count)
    }

    private func resetStates() {
        focusedAction = nil
        aboutToFocusedAction = nil
        resetExtendOffsetRatios()
    }
}

#Preview {
    ContentView()
}
