# Malzemecim Kurulum Talimatları

## Windows Kurulumu

### Sistem Gereksinimleri
- Windows 10 veya üzeri (64-bit)
- Visual C++ Redistributable 2015-2022 (otomatik olarak yüklenir veya manuel indirilebilir)

### Kurulum Adımları

1. **ZIP dosyasını indirin ve açın**
   - `malzemecim-windows-v1.0.0.zip` dosyasını indirin
   - ZIP dosyasını bir klasöre çıkarın (örneğin: `C:\Program Files\Malzemecim`)

2. **Visual C++ Redistributable Kontrolü**
   - Eğer uygulama çalışmazsa, Visual C++ Redistributable'ı indirip yükleyin:
   - İndirme linki: https://aka.ms/vs/17/release/vc_redist.x64.exe
   - Bu dosya Windows'un çoğu sürümünde zaten yüklüdür

3. **Uygulamayı Çalıştırma**
   - `malzemecim-windows-v1.0.0` klasörüne gidin
   - `malzemecim.exe` dosyasına çift tıklayarak uygulamayı başlatın

4. **Masaüstü Kısayolu Oluşturma (İsteğe Bağlı)**
   - `malzemecim.exe` dosyasına sağ tıklayın
   - "Masaüstü kısayolu oluştur" seçeneğini seçin

### Önemli Notlar
- Tüm dosyalar aynı klasörde olmalıdır (exe, dll, data klasörü vb.)
- Uygulamayı başka bir klasöre taşırsanız, tüm dosyaları birlikte taşıyın
- İlk çalıştırmada Windows Defender veya antivirüs uyarısı verebilir, bu normaldir

### Sorun Giderme

**Uygulama açılmıyor:**
- Visual C++ Redistributable'ın yüklü olduğundan emin olun
- Windows güncellemelerini kontrol edin
- Antivirüs yazılımının uygulamayı engellemediğinden emin olun

**DLL hatası alıyorsanız:**
- Tüm dosyaların aynı klasörde olduğundan emin olun
- `data` klasörünün mevcut olduğundan emin olun

---

## Android Kurulumu

### Sistem Gereksinimleri
- Android 5.0 (API 21) veya üzeri
- En az 100 MB boş depolama alanı

### Kurulum Adımları

1. **APK dosyasını indirin**
   - `malzemecim-android-v1.0.0.apk` dosyasını Android cihazınıza indirin

2. **Bilinmeyen Kaynaklardan Yükleme İzni**
   - Ayarlar > Güvenlik > Bilinmeyen Kaynaklardan Yükleme seçeneğini etkinleştirin
   - Veya APK'yı açarken "Bu kaynaktan yüklemeye izin ver" seçeneğini seçin

3. **APK'yı Yükleyin**
   - İndirilen APK dosyasına dokunun
   - "Yükle" butonuna tıklayın
   - İzinleri onaylayın

4. **Uygulamayı Başlatın**
   - Yükleme tamamlandıktan sonra "Aç" butonuna tıklayın
   - Veya uygulama menüsünden "Malzemecim" uygulamasını bulup açın

### Önemli Notlar
- İlk açılışta kamera, depolama ve internet izinleri istenebilir
- Bu izinler uygulamanın düzgün çalışması için gereklidir

### Sorun Giderme

**APK yüklenmiyor:**
- "Bilinmeyen kaynaklardan yükleme" izninin verildiğinden emin olun
- Cihazınızda yeterli depolama alanı olduğundan emin olun
- Eski bir sürüm varsa önce kaldırın, sonra yeni sürümü yükleyin

**Uygulama çöküyor:**
- Cihazınızın Android 5.0 veya üzeri olduğundan emin olun
- Uygulamayı kaldırıp yeniden yükleyin

---

## Versiyon Bilgisi
- **Versiyon:** 1.0.0+1
- **Build Tarihi:** $(Get-Date -Format "yyyy-MM-dd")

