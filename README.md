# RestoBook
Seminarski rad za predmet Razvoj Softvera II

## Upute za pokretanje

### 1. Pokretanje API-ja (Docker)
```bash
cd eCommerce
docker-compose up --build
```
API ce biti dostupan na: `http://localhost:5121/swagger/index.html`

### 2. Pokretanje Mobile aplikacije (Android)
1. Pokrenuti Android emulator (Android Studio -> Device Manager)
2. U terminalu navigirati do `eCommerce/UI/ecommerce_mobile`
3. Pokrenuti komandu:
```bash
flutter run --dart-define=baseUrl=http://10.0.2.2:5121/api/
```

**Napomena:** `10.0.2.2` je standardna adresa za Google Android Emulator AVD.

### 3. Pokretanje Desktop aplikacije (Windows)
1. U terminalu navigirati do `eCommerce/UI/ecommerce_desktop`
2. Pokrenuti komandu:
```bash
flutter run -d windows --dart-define=baseUrl=http://localhost:5121/api/
```

## Kredencijali

**Admin korisnik:**
- Korisnicko ime: `admin`
- Lozinka: `Admin123!`

**Klijent korisnik:**
- Korisnicko ime: `klijent`
- Lozinka: `Klijent123!`

## Sistem preporuke

Sistem preporuke koristi Content-Based Filtering algoritam za preporuku restorana korisnicima na osnovu njihovih preferencija (tip kuhinje, lokacija, ocjene, itd.).

Dokumentacija sistema preporuke se nalazi u fajlu: `Sistem preporuke - Dokuemntacija.docx`

## Build fajlovi

Release buildovi se nalaze u ZIP arhivi: `fit-build-2026-02-08.zip` (sifra: `fit`)

Sadrzi:
- Android APK: `app-release.apk`
- Windows executable: `ecommerce_desktop.exe`
