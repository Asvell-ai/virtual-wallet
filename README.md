# Hamyon

`Hamyon` — haqiqiy pul ishlatmaydigan, barcha ma'lumotni qurilmaning o'zida
saqlaydigan Flutter virtual hamyon demo ilovasi.

## Tayyor imkoniyatlar

- faqat UZCARD turidagi, 16 xonali raqam, nom va boshlang'ich balans bilan
  virtual karta qo'shish
- karta raqamini `8600 ** ** 1234` ko'rinishida yashirish
- kartalar o'rtasida 0.5% komissiyali pul o'tkazish
- mobil aloqa, internet va kommunal xizmatlar uchun to'lov
- bajarilgan va rad etilgan urinishlar tarixi
- tarixni turi va statusi bo'yicha filtrlash
- tranzaksiya chekini PDF qilib saqlash va `share_plus` orqali ulashish
- PIN bilan kirish va har bir pul operatsiyasini PIN bilan tasdiqlash
- 3 ta xato PINdan keyin 30 soniyalik blok
- ilova fonga o'tganda yoki 2 daqiqa ishlatilmaganda avtomatik qulf
- PBKDF2-HMAC-SHA256 + AES-256-GCM bilan shifrlangan lokal fayl
- har bir tranzaksiya uchun alohida HMAC-SHA256 imzo
- light/dark tema tanlovi va uni shifrlangan vault ichida saqlash
- barmoq izi yoki Face ID orqali hamyonni ochish
- karta ma’lumoti va tranzaksiya cheki uchun QR-kod
- premium banking dashboard, karta karuseli va yengil native animatsiyalar

## Arxitektura

Loyiha **feature-first Clean Architecture** tamoyiliga amal qiladi:

```text
lib/
├── core/                         # Faqat global va qayta ishlatiladigan qismlar
│   ├── error/                    # Umumiy Failure turlari
│   ├── security/                 # PBKDF2, AES-GCM, HMAC va vault
│   ├── theme/                    # Global tema
│   ├── utils/                    # Pul siyosati va formatterlar
│   └── widgets/                  # Bir nechta feature ishlatadigan widgetlar
└── features/
    ├── auth/                     # data / domain / presentation
    ├── cards/                    # data / domain / presentation
    ├── transfer/                 # data / domain / presentation
    ├── payments/                 # data / domain / presentation
    ├── history/                  # data / domain / presentation
    ├── receipt/                  # domain / presentation
    ├── qr/                       # domain / presentation
    ├── home/                     # presentation
    └── settings/                 # data / domain / presentation
```

Har bir feature o'z entity, repository contract, repository implementation,
use case, Cubit, state va sahifalariga ega. Global `data`, `domain` yoki
`presentation` papkalari yo'q.

UI'dagi biznes holati `Cubit state` ichida turadi. Alohida widget faqat bir
necha marta ishlatilsa yoki mustaqil, qayta ishlatiladigan komponent bo'lsa
chiqarilgan; bir martalik layoutlar sahifaning `build` qismida inline yozilgan.

## Pul hisoblash qoidasi

Pul `double` emas, butun `int` so'm ko'rinishida saqlanadi. Bu floating-point
xatolarini yo'q qiladi. Transfer bitta shifrlangan vault mutatsiyasi ichida
tekshiriladi va yoziladi:

1. manba va qabul qiluvchi kartalar qayta topiladi;
2. summa hamda komissiya tekshiriladi;
3. `source.balance >= amount + commission` invariant tekshiriladi;
4. ikkala balans va tranzaksiya bitta ketma-ket operatsiyada yoziladi;
5. yetarli mablag' bo'lmasa balans o'zgarmaydi, rad etilgan tranzaksiya tarixga
   yoziladi.

Komissiya formulasi:

```dart
commission = (amount * 5 + 999) ~/ 1000; // 0.5%, butun so'mga yuqoriga
```

## Xavfsizlik modeli

`hamyon_vault.dat` faylida karta yoki tranzaksiya JSON'i ochiq saqlanmaydi.
Faylda faqat KDF parametrlari, salt, nonce, ciphertext va authentication tag
bor.

- PIN'dan 210 000 iteratsiyali PBKDF2-HMAC-SHA256 orqali 64 bayt olinadi.
- Birinchi 32 bayt AES-256-GCM shifrlash kaliti.
- Ikkinchi 32 bayt tranzaksiya HMAC-SHA256 kaliti.
- Har yozishda yangi 96-bit nonce yaratiladi.
- AES-GCM fayl darajasidagi o'zgarishni, HMAC esa tranzaksiya darajasidagi
  o'zgarishni aniqlaydi.
- Kalitlar ilova qulflanganda xotiradan chiqariladi.
- Xato urinishlar va blok muddati `flutter_secure_storage` orqali saqlanadi.
- Biometrik kirish faqat foydalanuvchi PIN bilan yoqqanidan keyin ishlaydi;
  qurilma tasdig‘i `local_auth`, unlock ma’lumoti esa Keychain/Keystore orqali
  himoyalangan `flutter_secure_storage` yordamida boshqariladi.

> Bu o'quv/demo loyiha. Haqiqiy bank yoki PCI DSS talablari uchun mustaqil
> security audit, key attestation, jailbreak/root himoyasi va server tomondagi
> risk nazorati talab qilinadi.
