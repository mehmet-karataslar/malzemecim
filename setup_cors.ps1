# Firebase Storage CORS Ayarlarını Yapılandırma Scripti
# Bu script, Google Cloud SDK kullanarak Firebase Storage bucket'ına CORS ayarlarını uygular

Write-Host "Firebase Storage CORS Ayarlarını Yapılandırılıyor..." -ForegroundColor Green

# CORS.json dosyasının varlığını kontrol et
if (-not (Test-Path "cors.json")) {
    Write-Host "HATA: cors.json dosyası bulunamadı!" -ForegroundColor Red
    exit 1
}

# Google Cloud SDK'nın yüklü olup olmadığını kontrol et
$gsutilPath = Get-Command gsutil -ErrorAction SilentlyContinue

if (-not $gsutilPath) {
    Write-Host "Google Cloud SDK yüklü değil. Yükleniyor..." -ForegroundColor Yellow
    
    # Google Cloud SDK installer'ı indir
    $installerUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
    $installerPath = "$env:TEMP\GoogleCloudSDKInstaller.exe"
    
    Write-Host "Installer indiriliyor: $installerUrl" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    
    Write-Host "Installer indirildi. Lütfen installer'ı çalıştırın ve kurulumu tamamlayın." -ForegroundColor Yellow
    Write-Host "Kurulum tamamlandıktan sonra bu scripti tekrar çalıştırın." -ForegroundColor Yellow
    
    # Installer'ı çalıştır
    Start-Process -FilePath $installerPath -Wait
    
    # PATH'i yenile
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # gsutil'in yüklü olup olmadığını tekrar kontrol et
    $gsutilPath = Get-Command gsutil -ErrorAction SilentlyContinue
    if (-not $gsutilPath) {
        Write-Host "HATA: Google Cloud SDK kurulumu tamamlanamadı. Lütfen manuel olarak kurun." -ForegroundColor Red
        Write-Host "İndirme linki: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
        exit 1
    }
}

# Firebase projesini ayarla
Write-Host "Firebase projesi ayarlanıyor: malzemecim-21" -ForegroundColor Green
gcloud config set project malzemecim-21

# CORS ayarlarını uygula
Write-Host "CORS ayarları uygulanıyor..." -ForegroundColor Green
gsutil cors set cors.json gs://malzemecim-21.firebasestorage.app

if ($LASTEXITCODE -eq 0) {
    Write-Host "CORS ayarları başarıyla uygulandı!" -ForegroundColor Green
    Write-Host "Ayarların etkili olması birkaç dakika sürebilir." -ForegroundColor Yellow
} else {
    Write-Host "HATA: CORS ayarları uygulanamadı!" -ForegroundColor Red
    exit 1
}

