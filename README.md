# Malzemecim - Envanter & Veresiye Yönetim Sistemi

**İşletmenizin dijital dönüşümü için profesyonel çözüm**

Malzemecim, nalbur, hırdavat ve boya satış işletmeleri için özel olarak tasarlanmış, kapsamlı envanter ve veresiye yönetim sistemidir. Flutter teknolojisi ile geliştirilmiş, Android, iOS, Web ve Windows platformlarında sorunsuz çalışan modern bir işletme yönetim uygulamasıdır.

İşletmenizin stok takibinden veresiye yönetimine, barkod taramadan detaylı raporlamaya kadar tüm ihtiyaçlarını tek bir platformda birleştirir.

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Teknolojiler](#-teknolojiler)
- [Proje Yapısı](#-proje-yapısı)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Ekranlar ve Özellikler](#-ekranlar-ve-özellikler)
- [Firebase Yapılandırması](#-firebase-yapılandırması)
- [Geliştirme](#-geliştirme)
- [Lisans](#-lisans)

## ✨ Özellikler

### 🔐 Kimlik Doğrulama
- **Email/Şifre ile Giriş**: Güvenli Firebase Authentication entegrasyonu
- **Kullanıcı Kaydı**: İşletme bilgileri ile kayıt sistemi
- **Rol Tabanlı Erişim**: Admin ve Çalışan rolleri
- **Otomatik Oturum Yönetimi**: Kullanıcı durumu takibi

### 📦 Ürün Yönetimi
- **Ürün CRUD İşlemleri**: Ürün ekleme, düzenleme, silme ve listeleme
- **Kategori Yönetimi**: 10+ kategori desteği (Nalburiye, Boya, Elektrik, vb.)
- **Çoklu Birim Desteği**: Adet, KG, Litre, Metre, M², M³ ve daha fazlası
- **Stok Takibi**: Mevcut stok ve minimum stok seviyesi yönetimi
- **Düşük Stok Uyarıları**: Otomatik stok uyarı sistemi
- **Ürün Fotoğrafları**: Her ürün için en fazla 5 fotoğraf desteği
- **Barkod Yönetimi**: Ürünlere barkod atama ve takip

### 🔍 Barkod Tarama ve Entegrasyon
- **Kamera ile Tarama**: Mobil cihazlarda kamera ile hızlı barkod/QR kod tarama
- **USB Barkod Okuyucu Desteği**: Profesyonel USB barkod cihazları ile tam entegrasyon
- **Manuel Giriş**: Web platformunda esnek manuel barkod girişi seçeneği
- **Çoklu Format Desteği**: EAN-13, EAN-8, Code 128, Code 39, QR Code ve 10+ format desteği
- **Akıllı Ürün Eşleştirme**: Tarama sonrası otomatik ürün bulma ve işlem yapma

### 🔎 Gelişmiş Arama
- **Çoklu Arama Kriteri**: Ürün adı, marka, kategori, barkod ve açıklama
- **Akıllı Arama Algoritması**: Tam eşleşme öncelikli, kısmi eşleşme destekli
- **Barkod ile Arama**: Barkod numarası ile hızlı ürün bulma
- **Kategori Filtreleme**: Kategori bazlı filtreleme
- **Gerçek Zamanlı Arama**: Anlık arama sonuçları

### 💰 Veresiye Yönetimi
- **Müşteri Takibi**: Müşteri bilgileri ve iletişim yönetimi
- **Veresiye Kayıtları**: Aktif, ödenen ve vadesi geçen kayıtlar
- **Ödeme Takibi**: Kısmi ve tam ödeme kayıtları
- **Vade Takibi**: Vade tarihi ve gecikme uyarıları
- **Ödeme Geçmişi**: Detaylı ödeme geçmişi görüntüleme

### 📊 Raporlar ve Analiz
- **Düşük Stok Raporu**: Minimum stok seviyesinin altındaki ürünleri anında görüntüleyin
- **Veresiye Özeti**: Toplam veresiye tutarı ve ödeme durumu takibi
- **En Çok Aranan Ürünler**: Popüler ürün analizi ile satış stratejisi belirleyin
- **Aylık Özet**: Aylık satış ve stok özeti ile işletme performansını takip edin

### 📝 Notlar ve Hatırlatıcılar
- **Hızlı Notlar**: İşletme için anlık hatırlatma notları oluşturun
- **Not Yönetimi**: Not ekleme, düzenleme ve silme ile kolay organizasyon
- **Renkli Kategoriler**: Notları renklerle kategorize ederek hızlı erişim sağlayın

### ⚙️ Ayarlar ve Yönetim
- **Kullanıcı Profili**: Kullanıcı bilgileri ve rol yönetimi
- **Offline Senkronizasyon**: İnternet bağlantısı kesildiğinde offline çalışma desteği
- **Barkod Ayarları**: USB barkod okuyucu konfigürasyonu ve özelleştirme
- **Bildirim Ayarları**: Düşük stok ve ödeme hatırlatmaları
- **Veri Yedekleme**: Güvenli veri yedekleme ve geri yükleme (Admin)

### 🌐 Çoklu Platform Desteği
- **Android**: Tam özellik desteği ile mobil deneyim
- **iOS**: Tam özellik desteği ile iOS uyumluluğu
- **Web**: Web tarayıcı desteği ile her yerden erişim
- **Windows**: Masaüstü uygulama desteği ile ofis kullanımı

## 🛠 Teknolojiler

### Backend & Veritabanı
- **Firebase Authentication**: Kullanıcı kimlik doğrulama
- **Cloud Firestore**: NoSQL veritabanı
- **Firebase Storage**: Dosya ve görsel depolama

### State Management
- **Provider**: Durum yönetimi ve veri akışı

### UI/UX
- **Material Design 3**: Modern ve kullanıcı dostu arayüz
- **Google Fonts (Inter)**: Özel tipografi
- **Animations**: Akıcı geçiş animasyonları

### Özel Özellikler
- **mobile_scanner**: Barkod/QR kod tarama
- **image_picker**: Fotoğraf seçme ve çekme
- **cached_network_image**: Görsel önbellekleme
- **connectivity_plus**: İnternet bağlantı kontrolü
- **sqflite**: Yerel veritabanı (offline destek)
- **pdf & excel**: Rapor dışa aktarma

## 📁 Proje Yapısı

```
lib/
├── core/                          # Çekirdek yapı
│   ├── constants/                 # Sabitler
│   │   └── app_constants.dart    # Uygulama sabitleri
│   ├── services/                  # Servisler
│   │   └── firebase_service.dart # Firebase servisi
│   └── theme/                     # Tema
│       └── app_theme.dart        # Uygulama teması
│
├── features/                      # Özellik modülleri
│   ├── auth/                     # Kimlik doğrulama
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   │
│   ├── products/                 # Ürün yönetimi
│   │   ├── providers/
│   │   │   └── product_provider.dart
│   │   └── screens/
│   │       ├── products_screen.dart
│   │       ├── add_product_screen.dart
│   │       └── edit_product_screen.dart
│   │
│   ├── scanner/                  # Barkod tarama
│   │   └── screens/
│   │       └── scanner_screen.dart
│   │
│   ├── search/                   # Ürün arama
│   │   └── screens/
│   │       └── search_screen.dart
│   │
│   ├── credit/                   # Veresiye yönetimi
│   │   └── screens/
│   │       └── credit_screen.dart
│   │
│   ├── reports/                  # Raporlar
│   │   └── screens/
│   │       └── reports_screen.dart
│   │
│   ├── notes/                    # Notlar
│   │   └── screens/
│   │       └── notes_screen.dart
│   │
│   └── settings/                 # Ayarlar
│       └── screens/
│           └── settings_screen.dart
│
└── shared/                       # Paylaşılan bileşenler
    ├── models/                   # Veri modelleri
    │   ├── product_model.dart
    │   ├── inventory_model.dart
    │   ├── credit_model.dart
    │   └── user_model.dart
    │
    ├── providers/                # Global provider'lar
    │   ├── auth_provider.dart
    │   └── app_provider.dart
    │
    └── widgets/                  # Yeniden kullanılabilir widget'lar
        ├── main_navigation.dart
        ├── barcode_scanner_page.dart
        ├── usb_barcode_listener.dart
        ├── product_image_widget.dart
        ├── image_picker_widget.dart
        └── usb_device_status.dart
```

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK (3.8.1 veya üzeri)
- Dart SDK
- Firebase projesi
- Android Studio / Xcode (mobil geliştirme için)
- Visual Studio Code veya Android Studio (IDE)

### Adımlar

1. **Projeyi klonlayın**
```bash
git clone git@github.com:mehmet-karataslar/malzemecim.git
cd malzemecim
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Firebase yapılandırması**
   - Firebase Console'da yeni bir proje oluşturun
   - Android, iOS ve Web uygulamalarını ekleyin
   - `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını indirin
   - Firebase CLI ile yapılandırma:
   ```bash
   flutterfire configure
   ```

4. **Uygulamayı çalıştırın**
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 📱 Kullanım

### İlk Kullanım

1. **Kayıt Ol**: Uygulamayı ilk açtığınızda kayıt ekranına yönlendirilirsiniz
   - İşletme adı
   - Ad Soyad
   - Email
   - Şifre (en az 6 karakter)
   - İlk kayıt olan kullanıcı otomatik olarak **Admin** rolü alır

2. **Giriş Yap**: Kayıt olduktan sonra email ve şifre ile giriş yapabilirsiniz

### Ürün Yönetimi

#### Ürün Ekleme
1. Ana ekranda **Ürünler** sekmesine gidin
2. Sağ üst köşedeki **+** butonuna tıklayın
3. Ürün bilgilerini doldurun:
   - Ürün adı (zorunlu)
   - Marka
   - Kategori (zorunlu)
   - Birim fiyat (zorunlu)
   - Birim (Adet, KG, vb.)
   - Mevcut stok (zorunlu)
   - Minimum stok
   - Barkod (USB cihaz veya kamera ile tarayabilirsiniz)
   - Açıklama
   - Ürün fotoğrafları (en fazla 5 adet)

#### Ürün Düzenleme
1. Ürünler listesinde düzenlemek istediğiniz ürünün üzerine tıklayın
2. **Düzenle** butonuna tıklayın
3. Bilgileri güncelleyin ve **Kaydet** butonuna tıklayın

#### Ürün Silme
1. Ürün kartının sağ üst köşesindeki menü butonuna tıklayın
2. **Sil** seçeneğini seçin
3. Onaylayın (Ürün soft delete ile silinir, veritabanından tamamen kaldırılmaz)

### Barkod Tarama

#### Kamera ile Tarama
1. Ana ekranda **Tara** sekmesine gidin
2. Kamera izni verin
3. Barkod/QR kodu kameraya tutun
4. Otomatik olarak algılanır ve ürün aranır

#### USB Barkod Okuyucu ile Tarama
1. USB barkod okuyucuyu bilgisayarınıza bağlayın
2. Herhangi bir ekranda barkodu tarayın
3. Otomatik olarak ilgili alana doldurulur
4. Ürün ekleme veya arama ekranlarında otomatik olarak işlem yapılır

### Arama

1. **Arama** sekmesine gidin
2. Arama kutusuna ürün adı, marka, kategori veya barkod girin
3. Gerçek zamanlı sonuçlar görüntülenir
4. USB barkod okuyucu veya kamera ile de arama yapabilirsiniz

### Veresiye Yönetimi

1. **Veresiye** sekmesine gidin
2. Üç sekme bulunur:
   - **Aktif**: Ödenmemiş veresiye kayıtları
   - **Ödenen**: Tamamen ödenmiş kayıtlar
   - **Vadesi Geçen**: Vade tarihi geçmiş kayıtlar
3. Yeni veresiye eklemek için **+** butonuna tıklayın
4. Ödeme almak için kayıt üzerine tıklayıp **Ödeme Al** butonuna tıklayın

### Raporlar

1. **Raporlar** sekmesine gidin
2. İstediğiniz rapor kartına tıklayın:
   - Düşük Stok Raporu
   - Veresiye Toplam
   - En Çok Aranan Ürünler
   - Aylık Özet

### Notlar

1. **Notlar** sekmesine gidin
2. **+** butonuna tıklayarak yeni not ekleyin
3. Notları düzenleyebilir veya silebilirsiniz

## 🎨 Ekranlar ve Özellikler

### Ana Ekran (Bottom Navigation)
- **Tara**: Barkod tarama ekranı
- **Ürünler**: Ürün listesi ve yönetimi
- **Veresiye**: Veresiye kayıtları
- **Raporlar**: İşletme raporları
- **Arama**: Ürün arama
- **Notlar**: Hızlı notlar
- **Ayarlar**: Uygulama ayarları

### Rol Bazlı Erişim

#### Admin
- Tüm özelliklere tam erişim
- Ürün ekleme, düzenleme ve silme yetkisi
- Veresiye yönetimi ve takibi
- Kapsamlı rapor görüntüleme ve analiz
- Sistem yönetimi ve konfigürasyon

#### Çalışan
- Ürün bilgilerini görüntüleme
- Barkod tarama ve ürün arama
- Müşteri hizmetleri için gerekli tüm araçlar
- Kişisel ayarlar ve profil yönetimi

## 🔥 Firebase Yapılandırması

### Firestore Koleksiyonları

- **users**: Kullanıcı bilgileri
- **products**: Ürün bilgileri
- **inventory**: Stok hareketleri
- **credit**: Veresiye kayıtları
- **reports**: Rapor verileri
- **notes**: Notlar

### Güvenlik Kuralları

Firestore güvenlik kurallarını yapılandırmanız önerilir:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Credit collection
    match /credit/{creditId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 🧪 Geliştirme

### Kod Yapısı

Proje **Feature-First** mimarisi kullanmaktadır:
- Her özellik kendi modülünde
- Paylaşılan bileşenler `shared/` klasöründe
- Provider pattern ile state management
- Model-View-Provider (MVP) yaklaşımı

### Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

### Kod Standartları

- Dart/Flutter lint kurallarına uyun
- Türkçe yorumlar kullanın
- Açıklayıcı değişken ve fonksiyon isimleri
- Widget'ları küçük ve yeniden kullanılabilir tutun

## 📦 Bağımlılıklar

Ana bağımlılıklar:
- `firebase_core: ^3.6.0`
- `firebase_auth: ^5.3.1`
- `cloud_firestore: ^5.4.3`
- `firebase_storage: ^12.3.2`
- `provider: ^6.1.2`
- `mobile_scanner: ^5.2.3`
- `image_picker: ^1.1.2`
- `cached_network_image: ^3.4.1`
- `google_fonts: ^6.2.1`

Tam liste için `pubspec.yaml` dosyasına bakın.

## 💡 Öne Çıkan Özellikler

### 🚀 Performans ve Güvenilirlik
- **Hızlı ve Responsive**: Optimize edilmiş performans ile anında yanıt
- **Offline Çalışma**: İnternet bağlantısı olmasa bile temel işlemler devam eder
- **Güvenli Veri Yönetimi**: Firebase ile güvenli ve ölçeklenebilir altyapı
- **Gerçek Zamanlı Senkronizasyon**: Tüm cihazlarda anlık veri güncellemesi

### 🎯 İşletme Odaklı Çözümler
- **Kapsamlı Stok Yönetimi**: Düşük stok uyarıları ile stok takibi
- **Veresiye Takibi**: Müşteri borçlarını kolayca yönetin
- **Detaylı Raporlama**: İşletmenizin durumunu anlık görüntüleyin
- **Çoklu Platform**: Tek bir uygulama ile tüm cihazlarda çalışın

## 📄 Lisans

Bu proje özel bir projedir. Tüm hakları saklıdır.

## 👤 Geliştirici

**Mehmet Karataşlar**
- GitHub: [@mehmet-karataslar](https://github.com/mehmet-karataslar)

## 🙏 Teşekkürler

- Flutter ekibine harika bir framework için
- Firebase ekibine backend altyapısı için
- Tüm açık kaynak kütüphane geliştiricilerine

---

## 🎉 Neden Malzemecim?

Malzemecim, işletmenizin envanter ve veresiye yönetimini dijitalleştirerek:
- ⏱️ **Zaman Tasarrufu**: Hızlı barkod tarama ve otomatik işlemler
- 📊 **Veri Odaklı Kararlar**: Detaylı raporlar ile bilinçli kararlar
- 💰 **Gelir Artışı**: Düşük stok uyarıları ile satış kaybını önleyin
- 🔒 **Güvenli Veri**: Bulut tabanlı güvenli veri saklama
- 📱 **Her Yerden Erişim**: Mobil, tablet ve masaüstünde aynı deneyim

**Modern işletme yönetimi için Malzemecim ile tanışın!**
