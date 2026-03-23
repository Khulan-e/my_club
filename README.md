# ClubHub — ХУИС Оюутны клубуудын платформ

Flutter + Supabase дээр бүтэн систем.

---

## Файлын бүтэц

```
lib/
├── main.dart                          ← App entry point
├── models/
│   └── models.dart                    ← Бүх data model
├── providers/
│   └── auth_provider.dart             ← Auth state management
├── services/
│   └── supabase_service.dart          ← AuthService, ClubService,
│                                         JoinRequestService,
│                                         VolunteerHoursService,
│                                         ReviewService, EventService,
│                                         AdminService
├── utils/
│   └── theme_and_constants.dart       ← AppTheme, AppColors, AppConstants
├── widgets/
│   └── common_widgets.dart            ← Shared UI components
└── screens/
    ├── auth/
    │   └── auth_screens.dart          ← Login, Register,
    │                                     ForgotPassword, ChangePassword
    ├── student/
    │   └── student_screens.dart       ← Home, ClubDetail, MyProfile,
    │                                     MyHours, MyRequests,
    │                                     MyReviews, MyClubs
    └── admin/
        └── admin_dashboard_screen.dart ← Admin dashboard + tabs
supabase_schema.sql                    ← Database schema + RLS + seed data
```

---

## 1. Supabase тохируулах

1. [supabase.com](https://supabase.com) дээр шинэ project үүсгэнэ
2. **SQL Editor** руу орж `supabase_schema.sql` файлыг copy-paste хийж ажиллуулна
3. Project-ийн **Settings → API** дээрээс авна:
   - `Project URL`
   - `anon public` key

---

## 2. Flutter тохируулах

### pubspec.yaml — dependency нэмнэ

```yaml
dependencies:
  supabase_flutter: ^2.3.0
  provider: ^6.1.1
  google_fonts: ^6.1.0
  flutter_rating_bar: ^4.0.1
```

> ⚠️ `firebase_core`, `firebase_auth`, `cloud_firestore` — **хэрэглэхгүй**.
> Бүгдийг Supabase-ээр солисон.

```bash
flutter pub get
```

### main.dart дотор URL, key оруулна

```dart
await Supabase.initialize(
  url: 'https://ТАНЫ_PROJECT.supabase.co',
  anonKey: 'ТАНЫ_ANON_KEY',
);
```

---

## 3. Android тохируулах

`android/app/src/main/AndroidManifest.xml` дотор:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 4. iOS тохируулах

`ios/Runner/Info.plist` дотор:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 5. Эхний Админ бүртгэл үүсгэх

1. App дээр оюутан шиг бүртгүүлнэ
2. Supabase **Table Editor → users** дотор тухайн хэрэглэгчийн `role` талбарыг `admin` болгоно
3. Дахин нэвтэрч орно → Автоматаар Админы самбар руу орно

---

## Бүх функц

| Функц | Байдал |
|-------|--------|
| Бүртгүүлэх | ✅ |
| Нэвтрэх / Гарах | ✅ |
| Нууц үг сэргээх | ✅ |
| Нууц үг солих | ✅ |
| Профайл засах | ✅ |
| Клубуудын жагсаалт | ✅ |
| Клуб хайлт / шүүлт | ✅ |
| Клубийн дэлгэрэнгүй | ✅ |
| Элсэх хүсэлт илгээх | ✅ |
| Хүсэлтийн төлөв харах | ✅ |
| Миний клубүүд | ✅ |
| Сайн дурын цаг харах | ✅ |
| Үнэлгээ / сэтгэгдэл | ✅ |
| Админ: Dashboard | ✅ |
| Админ: Клуб удирдлага | ✅ |
| Админ: Хүсэлт батлах/татгалзах | ✅ |
| Админ: Сайн дурын цаг нэмэх | ✅ |
| Админ: Сэтгэгдэл хянах | ✅ |
| Row Level Security | ✅ |
| ХУИС-ийн 20 клуб seed data | ✅ |