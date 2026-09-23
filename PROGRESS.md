# BloodLink BD — অগ্রগতি প্রতিবেদন (Progress Report)

> তারিখ: সেপ্টেম্বর ২০২৬
> অবস্থা: **UI Prototype** — এখন পর্যন্ত শুধু ফ্রন্টএন্ড/ডিজাইন সম্পন্ন, কোনো backend নেই।

---

## ✅ যা যা করা হয়েছে (Done)

### App Base
- [x] Flutter প্রজেক্ট সেটআপ (`pubspec.yaml`, `main.dart`)
- [x] ডার্ক থিম সম্পূর্ণ (Material 3 + কাস্টম রং) — `theme/app_colors.dart`, `theme/app_theme.dart`
- [x] গ্লাসমরফিজম ডিজাইন সিস্টেম (Card, Button, Input) — `widgets/glass_*.dart`
- [x] রক্ত-লাল ব্র্যান্ডিং কালার + গ্র্যাডিয়েন্ট ব্যাকগ্রাউন্ড — `widgets/background_decor.dart`

### Navbar / Main Shell
- [x] ৫ ট্যাবের কাস্টম বটম নেভিগেশন (Home | Requests | **Donate** | Nearby | Profile)
- [x] কেন্দ্রে উঁচু করা ডোনেট FAB (ব্লাড ড্রপ আইকন)

### Home Screen
- [x] অ্যাসালামু আলাইকুম হেডার + নোটিফিকেশন ব্যাজ + প্রোফাইল অ্যাভাটার
- [x] লাল "Emergency Request" হিরো কার্ড + বাটন (UI মাত্র)
- [x] স্ট্যাট কার্ড (সক্রিয় ডোনার, বর্তমান রিকোয়েস্ট, কাছের ডোনার)
- [x] কাছের রিকোয়েস্ট লিস্ট (শীর্ষ ৩)
- [x] ডোনেশন কাউন্টডাউন কার্ড (শেষ ডোনেশন, পরবর্তী ডোনেশন তারিখ, প্রগ্রেস বার)

### Requests Screen
- [x] রিকোয়েস্ট সার্চ (গ্রুপ / এলাকা / হাসপাতাল / রোগীর নাম)
- [x] Urgency ফিল্টার চিপ (সব / জরুরি / দ্রুত / সাধারণ)
- [x] রিকোয়েস্ট কার্ড তালিকা (রোগী, গ্রুপ, হাসপাতাল, দূরত্ব, ব্যাগ, জরুরি লেভেল)

### Donate Screen (ডোনার কার্ড)
- [x] ডিজিটাল ডোনার কার্ড (নাম, Donor ID, ডোনেশন সংখ্যা)
- [x] QR কোড — CustomPainter দিয়ে নিজে আঁকা (ডামি)
- [x] অ্যাভেইলেবিলিটি টগল সুইচ (UI-তে কাজ করে, সংরক্ষণ হয় না)
- [x] ডোনেশন নিয়মাবলী তালিকা (Eligibility)
- [x] ডোনেশন হিস্টরি (স্ট্যাটিক ৩টি এন্ট্রি)

### Nearby Screen
- [x] কাস্টম ম্যাপ (CustomPainter) — শহরের ব্লক/রাস্তা দেখানো
- [x] ডোনার মার্কার + "আপনি" মার্কার + লেজেন্ড
- [x] কাছের ডোনার তালিকা (নাম, গ্রুপ, দূরত্ব, স্ট্যাটাস, ভেরিফিকেশন)

### Profile Screen
- [x] প্রোফাইল হেডার (নাম, এলাকা, ব্লাড গ্রুপ, ভেরিফাইড ব্যাজ)
- [x] স্ট্যাট গ্রিড (ডোনেশন, রেসপন্স রেট, রেটিং)
- [x] রেপুটেশন টায়ার (ব্রোঞ্জ → সিলভার → গোল্ড → প্ল্যাটিনাম) + প্রগ্রেস বার
- [x] সেটিংস মেনু (অ্যাকাউন্ট, প্রাইভেসি, নোটিফিকেশন, হেল্প, লগআউট) — UI মাত্র

### Data & Models
- [x] `BloodRequest` মডেল + `Urgency` এনাম (Critical / Urgent / Normal)
- [x] `Donor` মডেল + `DonorStatus` এনাম (Available / Busy / Unavailable)
- [x] মক ডেটা: ৬টি রিকোয়েস্ট + ৬ জন ডোনার (কুমিল্লা এলাকা, বাংলায়)

---

## 🟢 Phase 1 (সেপ্টেম্বর ২০২৬) — নতুন যা যোগ হয়েছে

- [x] Firebase dependencies (Core, Auth, Firestore, Messaging) + Android gradle plugin + minSdk 23 + নোটিফিকেশন পারমিশন
- [x] `AuthService` (Firebase Auth) + `AppUser` মডেল + Firestore-এ প্রোফাইল সেভ
- [x] Splash + Login + Register স্ক্রিন (ব্লাড গ্রুপ সিলেক্টর সহ)
- [x] `AuthGate` — লগইন না থাকলে LoginScreen, থাকলে MainShell
- [x] `NewRequestScreen` — ইমার্জেন্সি রিকোয়েস্ট ফর্ম (গ্রুপ, হাসপাতাল, এলাকা, ব্যাগ, জরুরি লেভেল, সময়) → Firestore-এ সেভ
- [x] `RequestService` — Firestore `requests` কালেকশন থেকে রিয়েল-টাইম রিকোয়েস্ট স্ট্রিম
- [x] Requests স্ক্রিন এখন লাইভ Firestore ডেটা দেখায় (সার্চ + urgency ফিল্টার সহ)
- [x] Home/Profile স্ক্রিনে আসল ইউজার ডেটা + কাজ করা লগআউট

### 🔔 FCM + ডোনার প্রতিক্রিয়া (আপডেটেড)
- [x] `NotificationService` — পারমিশন, token সেভ, blood-group টপিক সাবস্ক্রিপশন, foreground message
- [x] `MessagingWrapper` — অ্যাপ খোলা থাকা অবস্থায় notification স্ন্যাকবার দেখায়
- [x] রিকোয়েস্ট ডিটেইল স্ক্রিন + **"ডোনেট করব / হয়তো / পারব না"** অ্যাকশন বাটন
- [x] প্রতিক্রিয়া Firestore `requests/{id}/responses`-এ সেভ + `responseCount` আপডেট
- [x] সাড়া দেওয়া ডোনারদের লিস্ট (লাইভ)
- [x] কার্ডে ট্যাপ করলেই ডিটেইল খুলে
- [x] Cloud Function (`functions/index.js`) — নতুন রিকোয়েস্ট তৈরি হলে `blood_<group>` টপিকে পুশ (deploy করতে হবে)

---

## 🟢 Phase 2 (সেপ্টেম্বর ২০২৬) — GPS + আসল ম্যাপ + কম্প্যাটিবিলিটি + Availability

- [x] `LocationService` — geolocator: পারমিশন, কারেন্ট লোকেশন, haversine দূরত্ব (`location_service.dart`)
- [x] Android location পারমিশন (FINE + COARSE) — `AndroidManifest.xml`
- [x] `BloodCompat` — ব্লাড গ্রুপ কম্প্যাটিবিলিটি ম্যাট্রিক্স (`utils/blood_compat.dart`)
- [x] `AppUser` + `Donor` মডেলে latitude/longitude
- [x] `AuthService.setAvailable()` — availability toggle Firestore-এ সেভ হয় (Donate স্ক্রিন থেকে)
- [x] `NearbyScreen` — **আসল ম্যাপ (flutter_map + OpenStreetMap, API key লাগে না)** + কাছের ডোনার (লাইভ Firestore, দূরত্ব অনুসারে সাজানো, কম্প্যাটিবিলিটি ফিল্টার টগল)
- [x] রিকোয়েস্টে লোকেশন অ্যাটাচ (নতুন রিকোয়েস্টে user-এর lat/lng সেভ)
- [x] ডোনারদের locations অদ্যাপন (Nearby খুললেই নিজের অবস্থান সেভ)
- [x] Home-এর "কাছের রিকোয়েস্ট" এখন লাইভ Firestore ডেটা (শীর্ষ ৩)
- [x] DEBUG APK বিল্ড ✅ (`build\app\outputs\flutter-apk\app-debug.apk`)
- [x] Firestore rules (পুরো অ্যাপের জন্য — `firestore.rules` ফাইলে সেভ) `/users`, `/requests`, `/responses`, `/chat`

### 🤖 Smart Match + Call/Chat (আপডেটেড)
- [x] `MatchScorer` — ডোনার 0–100 ম্যাচ স্কোর (গ্রুপ + দূরত্ব + availability + verified + donations) — `utils/match_score.dart`
- [x] Nearby সর্ট টগল: **কাছে সবচেয়ে নিকট / স্মার্ট ম্যাচ ⚡** + কার্ডে `% ম্যাচ` ব্যাজ
- [x] RequestDetail-এ **স্মার্ট ম্যাচ** ব্লক (সেরা ৩ ডোনার)
- [x] ডোনারের **ফোন নম্বর** response-এ সেভ (`phone`) → `tel:` দিয়ে ডায়ালার খোলে
- [x] **রিয়েল-টাইম চ্যাট** — `requests/{id}/chat` সাবকলেকশন + `ChatScreen` (chat বাটন: হেডার ও প্রতিটি responder tile-এ)

> ⚠️ নোট: `proj4dart` + `latlong2` pub-cache-এ corrupted (NUL বাইট) ছিল — ডিলিট করে আবার `pub get` দিয়ে ঠিক হয়েছে। ভবিষ্যতে অনুরূপ `U+0000` error দেখা দিলে একই fix করবেন।

---

## ❌ যা যা বাকি আছে (Not Done)

### ১. Backend / Firebase
- [ ] Firebase Authentication (লগইন/রেজিস্টার)
- [ ] Cloud Firestore (ডেটাবেস)
- [ ] Firebase Cloud Messaging (FCM — পুশ নোটিফিকেশন)
- [ ] Firebase Storage (থাম্বনেইল/ছবি)
- [ ] Cloud Functions (বিজনেস লজিক)
- [ ] Admin Panel / Dashboard

### ২. Emergency Request Flow
- [ ] রিকোয়েস্ট তৈরির ফর্ম (Blood Group, Hospital, Location, তারিখ, ব্যাগ, Contact, Emergency Level)
- [ ] "Request Blood" সাবমিট → সিস্টেমে রিকোয়েস্ট যোগ
- [ ] রিকোয়েস্ট এক্সপায়ারি (auto-expiry) ও রি-ব্রডকাস্ট

### ৩. Smart Donor Matching
- [x] Match Score (Blood group compatibility + distance + availability + verified + donations history) — `utils/match_score.dart`, 0–100
- [x] কম্প্যাটিবল গ্রুপ টেবিল (যেমন O+ রোগী → O+, O− ডোনার) — `utils/blood_compat.dart`
- [x] Nearby তালিকায় "কাছে / স্মার্ট ম্যাচ ⚡" সর্ট টগল + ম্যাচ পার্সেন্টেজ ব্যাজ
- [x] RequestDetail-এ "স্মার্ট ম্যাচ" ব্লক (সেরা ৩ ডোনার, দূরত্ব + স্কোর)
- [ ] AI Emergency Matching / ইন্টেলিজেন্ট অ্যালার্ট ওয়েভ (Wave 1→2→3)

### ৪. Emergency Alert / Notification
- [x] FCM ক্লায়েন্ট সেটআপ (পারমিশন, token, topic)
- [x] রিকোয়েস্টে ডোনার রেসপন্স ("I Can Donate / Maybe / Can't") — অ্যাপে করা
- [x] Cloud Function লিখা আছে (deploy pending)
- [ ] Auto expire / re-broadcast
- [ ] স্মার্ট নোটিফিকেশন (দূরত্ব-ভিত্তিক Wave অ্যালার্ট)

### ৫. Donor–Patient Connection
- [x] কল (`tel:` ডায়ালার) — রেসপন্সকারী ডোনারের নম্বর সহ
- [x] রিয়েল-টাইম চ্যাট (প্রতি রিকোয়েস্টের আলাদা chat thread)
- [ ] হাসপাতাল ও রিকোয়েস্ট ডিটেইল শেয়ারিং
- [ ] প্রাইভেটি-প্রটেক্টেড যোগাযোগ (ফোন/ঠিকানা hidden)
- [ ] ব্লাড ব্যাগ রিজার্ভেশন (Need 3 → Reserved 2 → প্রয়োজনীয় 1)

### ৬. Location & Live Map
- [x] আসল GPS (geolocator) + **flutter_map/OpenStreetMap** (API key ছাড়া)
- [x] Live Nearby Donor জিও-লোকেশন (দূরত্ব অনুযায়ী সাজানো) + কম্প্যাটিবিলিটি ফিল্টার
- [x] রিকোয়েস্টে লোকেশন সেভ + Donor availability Firestore-এ persist
- [ ] exact address গোপন রেখে প্রায় অবস্থান দেখানো (রাস্তা-ব্লার) — বিকল্প উন্নতি

### ৭. Hospital System
- [ ] হাসপাতাল অ্যাকাউন্ট ও ভেরিফিকেশন
- [ ] হাসপাতালের রিকোয়েস্ট তৈরি/ভেরিফাই/কমপ্লিট
- [ ] Blood Bank স্টক সিস্টেম (Output: A+ 18 bags...)
- [ ] Supply vs Demand লাইভ বোর্ড
- [ ] ডোনার অ্যারাইভাল কনফার্মেশন

### ৮. Reputation & Certificate
- [ ] ডোনেশন ইতিহাস প্রজেক্টে (backend সেভ)
- [ ] ডিজিটাল সার্টিফিকেট / "Thank You" শেয়ার
- [ ] ফিডব্যাক লুপ — "Did it work?" (রোগী ↔ ডোনার)

### ৯. Safety & Anti-Fake
- [ ] ফোন ভেরিফিকেশন
- [ ] Fake Request প্রোটেকশন / রিপোর্ট সিস্টেম
- [ ] সন্দেহজনক অ্যাক্টিভিটি ডিটেকশন
- [ ] Screenshot গার্ড (প্রাইভেসি)

### ১০. Extra / Advanced
- [ ] Blood Shortage Heatmap
- [ ] Blood Camp ফাইন্ডার (গ্রুপ ড্রাইভ)
- [ ] সাইলেন্ট মোড / Quiet Zone
- [ ] ডোনার স্ট্রিক ও রি-ডোনেশন রিমাইন্ডার
- [ ] Bi-lingual টগল (বাংলা + ইংরেজি) — এখন শুধু বাংলা
- [ ] Offline SOS / SMS Fallback + USSD শর্ট-কোড
- [ ] অ্যাপ সেটিংসের কাজ (সব মেনু এখন ডেড বাটন)
- [ ] লগআউট/অ্যাকাউন্ট ডিলিট কার্যকর করা

---

## 📊 সারসংক্ষেপ

| বিভাগ | অবস্থা |
|---|---|
| UI / ডিজাইন | ✅ ৯০% সম্পন্ন (প্রায় সব স্ক্রিন রেডি) |
| Functional logic | ⚠️ প্রায় ৪০% (auth, Firestore, FCM, GPS, matching) |
| Backend / Data | ✅ Firebase Auth + Firestore (লাইভ) — মক ডেটা এখন শুধু ফলব্যাক |
| Location / Map | ✅ আসল GPS + flutter_map (OpenStreetMap) |
| Notification | ✅ FCM ক্লায়েন্ট + Cloud Function (deploy pending) |