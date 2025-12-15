# Firebase Storage CORS Ayarları

Web'de görsellerin yüklenmesi için Firebase Storage CORS ayarlarını yapılandırmanız gerekiyor.

## Yöntem 1: Google Cloud Console (Önerilen)

1. [Google Cloud Console](https://console.cloud.google.com/)'a giriş yapın
2. Proje olarak `malzemecim-21` seçin
3. Sol menüden **Cloud Storage** > **Browser** seçin
4. Bucket'ı seçin (`malzemecim-21.appspot.com`)
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

## Yöntem 2: gsutil (Google Cloud SDK gerekli)

Eğer Google Cloud SDK yüklüyse:

```bash
gsutil cors set cors.json gs://malzemecim-21.appspot.com
```

## Yöntem 3: Firebase CLI (Alternatif)

Firebase CLI ile de yapılandırılabilir, ancak Storage için doğrudan CORS desteği yoktur.

## Not

CORS ayarları yapılandırıldıktan sonra birkaç dakika içinde etkili olur. Tarayıcı cache'ini temizleyip tekrar deneyin.

