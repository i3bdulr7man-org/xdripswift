import UIKit

class EmailPopupViewController: UIViewController {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 15
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "أدخل بريدك الإلكتروني"
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "نحتاج بريدك الإلكتروني للتواصل معك وإرسال التحديثات المهمة حول التطبيق."
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "email@example.com"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        return tf
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("إرسال", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        return btn
    }()

    var onSubmit: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupLayout()
        submitButton.addTarget(self, action: #selector(submitPressed), for: .touchUpInside)
    }

    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // إغلاق النافذة بالنقر على الخلفية
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tap)
    }

    @objc private func backgroundTapped() {
        // يمكنك السماح بالإغلاق بالنقر على الخلفية
        // dismiss(animated: true)
    }

    private func setupLayout() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320)
        ])

        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, emailField, errorLabel, submitButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            emailField.heightAnchor.constraint(equalToConstant: 44),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func submitPressed() {
        guard let email = emailField.text, !email.isEmpty else {
            showError("الرجاء إدخال البريد الإلكتروني")
            return
        }

        guard isValidEmail(email) else {
            showError("البريد الإلكتروني غير صحيح")
            return
        }

        errorLabel.isHidden = true
        onSubmit?(email)
        dismiss(animated: true)
    }

    private func showError(_ msg: String) {
        errorLabel.text = msg
        errorLabel.isHidden = false
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
