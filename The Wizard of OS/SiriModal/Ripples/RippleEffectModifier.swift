import SwiftUI

/// A modifier that performs a ripple effect whenever its trigger value changes.
struct RippleEffect<T: Equatable>: ViewModifier {
    var origin: CGPoint
    var trigger: T

    init(at origin: CGPoint, trigger: T) {
        self.origin = origin
        self.trigger = trigger
    }

    func body(content: Content) -> some View {
        let origin = origin
        let duration = duration

        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(RippleModifier(
                origin: origin,
                elapsedTime: elapsedTime,
                duration: duration
            ))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }

    var duration: TimeInterval { 3 }
}

/// A modifier that applies a ripple effect.
struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var duration: TimeInterval
    var amplitude: Double = 12
    var frequency: Double = 15
    var decay: Double = 8
    var speed: Double = 2000

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )

        let maxSampleOffset = maxSampleOffset
        let elapsedTime = elapsedTime
        let duration = duration

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: maxSampleOffset,
                isEnabled: 0 < elapsedTime && elapsedTime < duration
            )
        }
    }

    var maxSampleOffset: CGSize {
        CGSize(width: amplitude, height: amplitude)
    }
}

// MARK: - macOS & iOS Compatible Gesture Modifier
extension View {
    func onPressingChanged(_ action: @escaping (CGPoint?) -> Void) -> some View {
        modifier(PressingGestureModifier(action: action))
    }
}

struct PressingGestureModifier: ViewModifier {
    var onPressingChanged: (CGPoint?) -> Void
    @State private var currentLocation: CGPoint?

    init(action: @escaping (CGPoint?) -> Void) {
        self.onPressingChanged = action
    }

    func body(content: Content) -> some View {
        #if os(macOS)
        let gesture = DragGesture(minimumDistance: 0)
            .onChanged { value in
                currentLocation = value.location
                onPressingChanged(currentLocation)
            }
            .onEnded { _ in
                currentLocation = nil
                onPressingChanged(nil)
            }
        #else
        let gesture = LongPressGesture(minimumDuration: 0.1)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    currentLocation = nil
                case .second(_, let drag?):
                    currentLocation = drag.location
                default:
                    break
                }
                onPressingChanged(currentLocation)
            }
            .onEnded { _ in
                currentLocation = nil
                onPressingChanged(nil)
            }
        #endif

        return content.gesture(gesture)
    }
}
