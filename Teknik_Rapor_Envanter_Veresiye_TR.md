# Teknik Rapor – Envanter & Veresiye Yönetim Sistemi

## 1. Projenin Amacı ve Kapsamı
Bu proje, nalbur/hırdavat/ boya satışı yapan bir işletmenin ürünlerini, stoklarını, fiyatlarını, veresiye defterini ve barkod/QR tabanlı hızlı sorgulamalarını **mobil ve web üzerinden** yönetebilmesini sağlamayı amaçlar.  
Satış ve fatura kesme süreci dahil değildir. Proje yalnızca stok/fiyat/veresiye/raporlama yönetimine odaklanır.

---

## 2. Kullanıcı Rolleri
- **İşletme Sahibi (Admin):** Tüm yetkilere sahiptir. Ürün ekleme, silme, güncelleme, stok kontrol, veresiye yönetimi, raporlar.  
- **Çalışan (Sorgu Yetkili):** Sadece ürün sorgulama (barkod/fiyat) ve stok görüntüleme yapar. Ürün ekleyemez/silemez.

---

## 3. Sekmeler ve İşlevleri

### 3.1 Anasayfa / Tara
- Barkod/QR kod okutulduğunda ürün bilgisi otomatik ekrana gelir.  
- Ürün adı, marka, fiyat, stok, fotoğraf gösterilir.  
- Admin ek olarak anlık **KDV ve iskonto** girip müşteriye özel fiyatı hızlı hesaplayabilir.

### 3.2 Ürünler
- Ürün ekleme, silme, güncelleme.  
- Çoklu birim desteği (adet, kg, litre, metre, m², m³).  
- Fotoğraf yükleme (tek veya çoklu).  
- Stok takibi (minimum stok seviyesi belirleme).  
- Ürün arama: isim, marka, barkod, SKU, açıklama vb. kriterlere göre.  

### 3.3 Veresiye (Borç Defteri)
- Ad, soyad, telefon, alınan ürün(ler), miktar, fiyat ve not kaydı.  
- Borç kayıtları listelenir ve raporlanır.  
- Borç kapatma/güncelleme desteği.  

### 3.4 Raporlar
- Düşük stok raporu (minimum seviyenin altına düşenler).  
- En çok sorgulanan ürünler.  
- Veresiye toplamları.  
- Günlük/haftalık/aylık stok değişim raporları.

### 3.5 Arama
- Tüm ürünler içinde marka, ad, barkod, SKU veya açıklamaya göre arama.  
- Çoklu filtreleme desteği.

### 3.6 Ayarlar
- Kullanıcı yetkileri yönetimi.  
- Barkod cihaz entegrasyonu (Enter tuşu olmadan otomatik sorgu).  
- Offline kullanım (önbelleğe alma).  
- Tema sabit (koyu mavi & beyaz). Dil desteği yok.  

### 3.7 Hızlı Not
- Günlük basit notlar (ör: müşteri için hızlı hatırlatma).  
- Notlar tarih bazlı listelenir.

---

## 4. İş Kuralları
- Barkod okutulduğunda otomatik sorgu yapılır, kullanıcıdan ek işlem beklenmez.  
- KDV oranı ve iskonto yalnızca Admin tarafında görünür.  
- Ürün silme/güncelleme yalnızca Admin’e açıktır.  
- Veriler internet yokken cihazda saklanır, internet geldiğinde Firebase ile senkronize edilir.  

---

## 5. Cihaz ve Entegrasyon
- **Mobil cihazlar:** Kamera ile QR kod tarama.  
- **PC:** USB barkod okuyucu desteği (otomatik fiyat sorgulama).  
- Her iki platform da aynı veritabanını (Firebase) kullanır.

---

## 6. Güvenlik
- Firebase Authentication ile kullanıcı doğrulama.  
- Firestore Security Rules ile rol bazlı yetki kontrolü.  
- Veriler SSL/TLS üzerinden taşınır.

---

## 7. Performans Hedefleri
- Barkod okuma → ürün bilgisi ekrana gelme: < 1 sn.  
- Offline → online geçişte veri kaybı olmaması.  
- 10.000’den fazla ürün kaydı için stabil çalışma.

---

## 8. UX & Tasarım
- Mobil öncelikli (responsive).  
- Tema sabit: koyu mavi (#1e3a8a), beyaz (#ffffff).  
- Büyük butonlar, kolay erişilebilir alanlar.  

---

## 9. Test Stratejisi
- **Unit Test:** Barkod okuma, stok güncelleme fonksiyonları.  
- **Integration Test:** Firebase senkronizasyonu.  
- **User Acceptance Test:** İşletme sahibinin günlük kullanım senaryoları.  

---

## 10. Riskler ve Önlemler
- **İnternetsiz kullanımda veri kaybı** → Offline cache + senkronizasyon.  
- **Yanlış fiyat bilgisi** → Admin onaylı güncelleme.  
- **Cihaz uyumsuzluğu** → Tarayıcı tabanlı fallback arayüz.  

---

## 11. Yol Haritası
1. **Faz 1:** Barkod okuma & ürün sorgulama (mobil/PC).  
2. **Faz 2:** Ürün ekleme, stok takibi, çoklu birim.  
3. **Faz 3:** Veresiye defteri.  
4. **Faz 4:** Raporlama & düşük stok uyarıları.  
5. **Faz 5:** Offline desteği & performans optimizasyonu.  

---

## 12. Başarı Ölçütleri (KPI)
- Barkod sorgulama hızı.  
- Hatalı fiyat/ürün oranı.  
- Offline senkron başarı oranı.  
- Kullanıcı memnuniyeti (%80+).  

---

