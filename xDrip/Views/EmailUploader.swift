import CryptoKit
import Foundation

/// يرفع البريد إلى Google Apps Script مع توقيع HMAC-SHA256 لمنع الطلبات المزيفة.
///
/// لماذا التوقيع داخل جسم الطلب وليس ترويسة HTTP؟ لأن مشغلات الويب في
/// Apps Script لا تعرض ترويسات الطلب للسكربت، فلا يمكن التحقق منها خادميًا.
///
/// تم التدوير 2026-09-14: النشر القديم المكشوف في تاريخ git أُرشف (يرجع 404)
/// وهذا هو النشر الجديد المُختبَر. السر المشترك يجب أن يطابق SHARED_SECRET في
/// scripts/email-collector/Code.gs عند أي تغيير مستقبلي.
enum EmailUploader {

    private static let endpoint = URL(string: "https://script.google.com/macros/s/AKfycbxR55EXmUIgsnK9EcaZxHjARL8gUpdLnT1PwHSjcf6AOvZXyOTCeaUsLAEjstpP-EjiQA/exec")!

    /// سر مشترك مع سكربت Google — يجب أن يطابق SHARED_SECRET في scripts/email-collector/Code.gs
    private static let sharedSecret = SymmetricKey(data: Data("0a371d7e7fd3fdee6fd23724246d621740c0bab0bab8c2a30fd0ac443c795c7f".utf8))

    /// يسجّل الطابع الزمني (بالثواني) الذي يقيّد إعادة تشغيل الطلب خادميًا
    private static let replayWindowSeconds = 600

    /// يرسل البريد موقّعًا؛ completion تُستدعى من خلفية الشبكة بنتيجة الإرسال (true عند "ok" من الخادم)
    static func send(email: String, completion: ((Bool) -> Void)? = nil) {
        let timestamp = String(Int(Date().timeIntervalSince1970))

        let payload: [String: String] = [
            "email": email,
            "timestamp": timestamp,
            "signature": signature(email: email, timestamp: timestamp)
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            completion?(body.contains("ok"))
        }.resume()
    }

    /// توقيع الرسالة "email\ntimestamp" — نفس المعادلة في Code.gs (hmacSha256Hex_)
    private static func signature(email: String, timestamp: String) -> String {
        let message = Data("\(email)\n\(timestamp)".utf8)
        return HMAC<SHA256>.authenticationCode(for: message, using: sharedSecret)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
