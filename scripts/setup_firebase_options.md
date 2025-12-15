# Firebase Options Dosyası Kurulumu

`firebase_options.dart` dosyası API key'ler içerdiği için Git'e eklenmemiştir.

## Yeni Geliştirici İçin Kurulum

1. **FlutterFire CLI ile otomatik oluşturma (Önerilen):**
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```
   Bu komut `lib/firebase_options.dart` dosyasını otomatik oluşturur.

2. **Manuel oluşturma:**
   - `lib/firebase_options.dart.template` dosyasını `lib/firebase_options.dart` olarak kopyalayın
   - Firebase Console'dan API key'lerinizi alın ve dosyaya ekleyin
   - Firebase Console: https://console.firebase.google.com
   - Proje: malzemecim-21
   - Project Settings > General > Your apps

## Firebase Console'dan Key'leri Alma

1. Firebase Console'a gidin: https://console.firebase.google.com
2. Projenizi seçin: **malzemecim-21**
3. ⚙️ **Project Settings** > **General** sekmesine gidin
4. **Your apps** bölümünden her platform için:
   - **Web**: `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`, `storageBucket`, `measurementId`
   - **Android**: `apiKey`, `appId`, `messagingSenderId`, `projectId`, `storageBucket`
   - **iOS**: `apiKey`, `appId`, `messagingSenderId`, `projectId`, `storageBucket`, `iosBundleId`
   - **Windows**: `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`, `storageBucket`, `measurementId`

## Güvenlik Notu

⚠️ **ÖNEMLİ**: Bu dosyayı asla Git'e commit etmeyin! `.gitignore` dosyasına eklenmiştir.

