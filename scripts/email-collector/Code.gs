/**
 * خادم جمع البريد الإلكتروني — Google Apps Script
 *
 * بديل مُحصّن للسكربت السابق: يتحقق من توقيع HMAC-SHA256 الصادر من التطبيق،
 * يرفض الطلبات المعاد تشغيلها (أقدم من 10 دقائق)، ويحدّ من معدل الطلبات.
 *
 * خطوات التشغيل:
 * 1. أنشئ نشرًا جديدًا (Deploy > New deployment > Web app) — لا تعد استخدام
 *    رابط النشر القديم لأنه انكشف في تاريخ git للمستودع.
 * 2. انسخ SHARED_SECRET من xdrip/Views/EmailUploader.swift كما هو.
 * 3. ضع معرّف Google Sheet في SPREADSHEET_ID (الورقة التي تجمع البريد).
 * 4. الصق هذا الملف مكان doPost القديم ثم انشر (Deploy).
 * 5. حدّث `endpoint` في EmailUploader.swift بالرابط الجديد.
 */

// يجب أن يطابق sharedSecret في xdrip/Views/EmailUploader.swift
var SHARED_SECRET = '0a371d7e7fd3fdee6fd23724246d621740c0bab0bab8c2a30fd0ac443c795c7f';

// نافذة صلاحية الطلب بالثواني (نفس replayWindowSeconds في التطبيق)
var REPLAY_WINDOW_SECONDS = 600;

// حد أقصى للطلبات في الدقيقة عبر المتصفح كله (حماية من الإغراق)
var MAX_REQUESTS_PER_MINUTE = 10;

// معرّف Google Sheet الذي تُلحق به الصفوف
var SPREADSHEET_ID = 'PASTE_YOUR_SPREADSHEET_ID_HERE';

function doPost(e) {
  try {
    if (!e.postData || !rateLimitAllows_()) {
      return respond_('rejected: busy');
    }

    var body = JSON.parse(e.postData.contents);
    var email = String(body.email || '');
    var timestamp = Number(body.timestamp || 0);
    var signature = String(body.signature || '');

    // 1) التحقق من التوقيع (نفس معادلة التطبيق: hmac("email\ntimestamp"))
    var expected = hmacSha256Hex_(email + '\n' + timestamp);
    if (signature.length !== 64 || !fixedTimeEquals_(signature, expected)) {
      return respond_('rejected: signature');
    }

    // 2) رفض الطلبات القديمة/المستقبلية (منع إعادة التشغيل)
    var now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - timestamp) > REPLAY_WINDOW_SECONDS) {
      return respond_('rejected: stale');
    }

    // 3) تحقق أساسي من الصيغة
    if (!/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(email)) {
      return respond_('rejected: format');
    }

    // 4) تجاهل التكرار ثم الإلحاق
    var sheet = SpreadsheetApp.openById(SPREADSHEET_ID).getSheets()[0];
    var existing = sheet.getRange('A:A').getValues().flat();
    if (existing.indexOf(email) === -1) {
      sheet.appendRow([email, new Date()]);
    }

    return respond_('ok');
  } catch (err) {
    return respond_('rejected: error');
  }
}

function respond_(text) {
  return ContentService.createTextOutput(text).setMimeType(ContentService.MimeType.TEXT);
}

function rateLimitAllows_() {
  var store = PropertiesService.getScriptProperties();
  var key = 'rl_' + Math.floor(Date.now() / 60000); // نافذة دقيقة واحدة
  var count = Number(store.getProperty(key) || 0);
  if (count >= MAX_REQUESTS_PER_MINUTE) return false;
  store.setProperty(key, String(count + 1));
  return true;
}

function hmacSha256Hex_(message) {
  var raw = Utilities.computeHmacSha256Signature(message, SHARED_SECRET);
  return raw.map(function (b) {
    return ('0' + (b & 0xff).toString(16)).slice(-2);
  }).join('');
}

function fixedTimeEquals_(a, b) {
  if (a.length !== b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
