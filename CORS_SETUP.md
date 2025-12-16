# Firebase Storage CORS Ayarları

Web'de görsellerin yüklenmesi için Firebase Storage CORS ayarlarını yapılandırmanız gerekiyor.

## Yöntem 1: Google Cloud Console (Önerilen)

1. [Google Cloud Console](https://console.cloud.google.com/)'a giriş yapın
2. Proje olarak `malzemecim-21` seçin
3. Sol menüden **Cloud Storage** > **Browser** seçin
4. Bucket'ı seçin (`malzemecim-21.firebasestorage.app`)
5. **Permissions** sekmesine gidin
6. **CORS Configuration** bölümüne gidin
7. Aşağıdaki JSON'u ekleyin:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

## Yöntem 2: PowerShell Script (Otomatik Kurulum)

Windows'ta otomatik olarak Google Cloud SDK'yı yükleyip CORS ayarlarını yapılandırmak için:

```powershell
.\setup_cors.ps1
```

Bu script:
1. Google Cloud SDK'nın yüklü olup olmadığını kontrol eder
2. Yüklü değilse otomatik olarak indirip yükler
3. CORS ayarlarını Firebase Storage bucket'ına uygular

## Yöntem 3: Google Cloud Shell (En Kolay - Önerilen)

1. [Google Cloud Console](https://console.cloud.google.com/)'a giriş yapın
2. Proje olarak `malzemecim-21` seçin
3. Sağ üst köşedeki **Cloud Shell** simgesine (">_") tıklayın
4. Cloud Shell açıldığında, aşağıdaki komutları çalıştırın:

```bash
# CORS.json dosyasını oluştur
cat > cors.json << 'EOF'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
EOF

# CORS ayarlarını uygula
gsutil cors set cors.json gs://malzemecim-21.firebasestorage.app

# Ayarları doğrula
gsutil cors get gs://malzemecim-21.firebasestorage.app
```

## Yöntem 4: gsutil (Manuel - Google Cloud SDK gerekli)

Eğer Google Cloud SDK zaten yüklüyse ve PATH'te ise:

```bash
gsutil cors set cors.json gs://malzemecim-21.firebasestorage.app
```

**Not:** Windows'ta tam yol kullanmanız gerekebilir:
```powershell
&"C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd" cors set cors.json gs://malzemecim-21.firebasestorage.app
```

## Yöntem 3: Firebase CLI (Alternatif)

Firebase CLI ile de yapılandırılabilir, ancak Storage için doğrudan CORS desteği yoktur.

## Not

CORS ayarları yapılandırıldıktan sonra birkaç dakika içinde etkili olur. Tarayıcı cache'ini temizleyip tekrar deneyin.

