func sendEmailToServer(email: String) {
    let url = URL(string: "https://script.google.com/macros/s/AKfycbzgZ1M8K8UmUmDA02ySvW6MK8glYvDc0lSD71C0j0hlpbwIYBQRZUa5_kLQ2tJqkMFz4A/exec")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST" // يجب أن يكون POST
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let json = ["email": email]
    request.httpBody = try? JSONSerialization.data(withJSONObject: json)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Failed sending email:", error.localizedDescription)
        } else {
            if let data = data, let str = String(data: data, encoding: .utf8) {
                print("Response from Google:", str)
            }
        }
    }.resume()
}
