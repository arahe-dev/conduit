import SwiftUI
import UIKit

enum ComposePull {
    static func resist(_ translation: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let x = max(0, translation)
        let width = max(pageWidth, 1)
        return width * (1 - exp(-x / (width * 0.36)))
    }

    static func shouldCommit(
        translation: CGFloat,
        predicted: CGFloat,
        pageWidth: CGFloat,
        relaxed: Bool
    ) -> Bool {
        let threshold = pageWidth * (relaxed ? 0.12 : 0.34)
        return translation > threshold || predicted > pageWidth * (relaxed ? 0.18 : 0.48)
    }

    static func shouldDismiss(translation: CGFloat, predicted: CGFloat, pageWidth: CGFloat) -> Bool {
        translation > pageWidth * 0.18 || predicted > pageWidth * 0.28
    }
}

/// Observes the pager's own pan so workspace paging stays native. Left-pull past the last
/// space is mapped through `ComposePull.resist` instead of UIScrollView bounce.
struct ComposePullCatcher: UIViewRepresentable {
    var onLastSpace: Bool
    var composeOpen: Bool
    var pageWidth: CGFloat
    var onPeekChanged: (CGFloat) -> Void
    var onPeekEnded: (CGFloat, CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onLastSpace = onLastSpace
        coordinator.composeOpen = composeOpen
        coordinator.pageWidth = pageWidth
        coordinator.onPeekChanged = onPeekChanged
        coordinator.onPeekEnded = onPeekEnded
        DispatchQueue.main.async {
            coordinator.install(from: uiView)
        }
    }

    final class Coordinator: NSObject {
        var onLastSpace = false
        var composeOpen = false
        var pageWidth: CGFloat = 390
        var onPeekChanged: (CGFloat) -> Void = { _ in }
        var onPeekEnded: (CGFloat, CGFloat) -> Void = { _, _ in }

        private weak var scrollView: UIScrollView?
        private var observing = false
        private var pulling = false

        func install(from probe: UIView) {
            guard let scroll = Self.findPagingScrollView(from: probe) else { return }
            scroll.bounces = false
            scroll.alwaysBounceHorizontal = false
            if !observing || scrollView !== scroll {
                scrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
                scroll.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
                observing = true
                scrollView = scroll
            }
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard !composeOpen, let scroll = scrollView else { return }
            let maxX = max(0, scroll.contentSize.width - scroll.bounds.width)
            let atEnd = scroll.contentOffset.x >= maxX - 1
            let translation = gesture.translation(in: scroll)
            let velocity = gesture.velocity(in: scroll)
            let raw = max(0, -translation.x)
            let predicted = max(0, -(translation.x + velocity.x * 0.22))

            switch gesture.state {
            case .changed:
                if (onLastSpace && atEnd && translation.x < 0) || pulling {
                    pulling = translation.x < 0
                    scroll.contentOffset.x = maxX
                    onPeekChanged(raw)
                }
            case .ended, .cancelled, .failed:
                if pulling || (onLastSpace && atEnd && raw > 8) {
                    pulling = false
                    onPeekEnded(raw, predicted)
                } else {
                    pulling = false
                }
            default:
                break
            }
        }

        private static func findPagingScrollView(from view: UIView) -> UIScrollView? {
            var ancestor: UIView? = view
            while let current = ancestor {
                if let found = search(current) { return found }
                ancestor = current.superview
            }
            return nil
        }

        private static func search(_ view: UIView) -> UIScrollView? {
            if let scroll = view as? UIScrollView {
                let wide = scroll.contentSize.width > max(scroll.bounds.width, 1) * 1.5
                if scroll.isPagingEnabled || wide {
                    return scroll
                }
            }
            for child in view.subviews {
                if let found = search(child) { return found }
            }
            return nil
        }
    }
}
