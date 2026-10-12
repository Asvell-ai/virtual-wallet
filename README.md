<div align="center">

# Hamyon

**Xavfsiz, local-first virtual hamyon — Flutter'da yaratilgan.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart&logoColor=white)](https://dart.dev)
![Architecture](https://img.shields.io/badge/Architecture-Clean-6C63FF)
![State Management](https://img.shields.io/badge/State-Cubit-7B61FF)

Hamyon — virtual kartalar, pul o'tkazmalari va kundalik to'lovlarni boshqarish uchun yaratilgan mobil demo ilova. U fintech interfeyslari, lokal ma'lumotlar xavfsizligi va Clean Architecture yondashuvini amaliy ko'rsatadi.

> Ilova haqiqiy bank tizimiga ulanmaydi va real pul bilan ishlamaydi.

</div>

## Ilova ko'rinishi

<table>
  <tr>
    <th>1. PIN orqali kirish</th>
    <th>2. Asosiy sahifa</th>
    <th>3. Karta tafsilotlari</th>
  </tr>
  <tr>
    <td><img src="assets/templates/01-auth-pin.png" alt="PIN orqali kirish" width="280" /></td>
    <td><img src="assets/templates/02-home-overview.png" alt="Hamyon asosiy sahifasi" width="280" /></td>
    <td><img src="assets/templates/03-card-details.png" alt="Virtual karta tafsilotlari" width="280" /></td>
  </tr>
  <tr>
    <th>4. Tranzaksiya cheki</th>
    <th>5. Sozlamalar</th>
    <th>6. Dark mode</th>
  </tr>
  <tr>
    <td><img src="assets/templates/04-transaction-receipt.png" alt="Tranzaksiya cheki" width="280" /></td>
    <td><img src="assets/templates/05-settings-dark-mode.png" alt="Xavfsizlik va tema sozlamalari" width="280" /></td>
    <td><img src="assets/templates/06-home-dark-mode.png" alt="Dark mode asosiy sahifasi" width="280" /></td>
  </tr>
</table>

## Nimalar qila oladi?

- UZCARD virtual kartalarini qo'shish va balansni boshqarish
- Kartalar o'rtasida 0.5% komissiya bilan pul o'tkazish
- Mobil aloqa, internet va kommunal xizmatlar uchun to'lov qilish
- Muvaffaqiyatli va rad etilgan tranzaksiyalar tarixini filtrlash
- Chekni QR-kodda ko'rsatish, PDF saqlash yoki ulashish
- PIN, Face ID yoki barmoq izi bilan himoyalanish
- Light va dark mavzulardan foydalanish

## Xavfsizlik

Ma'lumotlar qurilmaning o'zida saqlanadi. Vault `PBKDF2-HMAC-SHA256` asosidagi kalit, `AES-256-GCM` shifrlash va har bir tranzaksiya uchun `HMAC-SHA256` imzo bilan himoyalangan. Uchta noto'g'ri PIN urinishidan so'ng vaqtinchalik blok yoqiladi; ilova fonga o'tganda yoki ikki daqiqa faol bo'lmaganda avtomatik qulflanadi.

## Arxitektura

Loyiha feature-first Clean Architecture asosida tuzilgan:

```text
lib/
├── core/                 # Theme, security, utilities, shared widgets
└── features/
    ├── auth/             # Data / Domain / Presentation
    ├── cards/
    ├── transfer/
    ├── payments/
    ├── history/
    ├── receipt/
    ├── qr/
    ├── home/
    └── settings/
```

Har bir feature repository, use case va Cubit orqali ajratilgan. Pul qiymatlari aniqlikni saqlash uchun `double` emas, butun `int` so'm ko'rinishida yuritiladi.

## Ishga tushirish

```bash
flutter pub get
flutter run
```
