import UIKit

enum KeyboardSupport {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Pre-warms the keyboard system so the first real focus does not hitch.
    static func warmUp() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
            else { return }

            let field = UITextField(frame: CGRect(x: 0, y: -200, width: 1, height: 1))
            field.alpha = 0.01
            field.autocorrectionType = .no
            window.addSubview(field)
            field.becomeFirstResponder()
            field.resignFirstResponder()
            field.removeFromSuperview()
        }
    }
}
