# CepSepeti Test Asamasi Yapilacaklar

Tarih: 12 Temmuz 2026

Bu dosya, Asema 1-5 sonrasinda uygulamayi gercek kullanim akisiyla test etmek icin hazirlandi. Amac, yeni asenkron tarama kuyrugunun kullanici akisini durdurmadan calistigini ve yanlis urune sonuc yazmadigini dogrulamaktir.

## 1. Test Oncesi Hazirlik

- Xcode ile projeyi ac.
- Uygulamayi simulator veya gercek cihazda calistir.
- Kamera testi icin gercek cihaz tercih et; simulator kamera akisini dogru temsil etmeyebilir.
- Internet baglantisinin acik oldugu bir test ve kapali oldugu bir test yap.
- Test edilecek en az 5 farkli market raf etiketi hazirla.
- Mumkunse etiketlerin fotograflari farkli zorluklarda olsun:
  - Net ve yakin etiket
  - Uzak veya hafif bulanik etiket
  - Birim fiyat iceren etiket
  - Kampanya veya coklu fiyat iceren etiket
  - Barkod, tarih, KDV gibi gurultu iceren etiket

## 2. Temel Tek Urun Testi

1. Yeni alisveris baslat.
2. Bir raf etiketi tara.
3. Fotograf cekildikten sonra urunun hemen sepete eklendigini kontrol et.
4. Sepette urun once `Sirada...` veya `Analiz ediliyor...` durumunda gorunmeli.
5. Kamera AI sonucunu beklemeden tekrar kullanilabilir olmali.
6. Sonuc geldiginde urun adi, marka ve fiyat dolmali.
7. Toplam tutarin yalnizca tamamlanmis urunle guncellendigini kontrol et.

Beklenen sonuc:

- Uygulama tam ekran uzun sureli AI bekleme ekraninda kalmamali.
- Urun sepette kaybolmamali.
- Marka varsa urun detayina yazilmali.
- Fiyat satis fiyati olmali, birim fiyat olmamali.

## 3. Art Arda Coklu Tarama Testi

1. Yeni alisveris baslat.
2. Bes etiketi hizlica arka arkaya tara.
3. Her taramadan sonra kameranin yeniden kullanilabilir oldugunu kontrol et.
4. Sepeti ac.
5. Bes gecici urunun listede gorundugunu kontrol et.
6. Sonuclar geldikce her urunun kendi kartinda guncellendigini kontrol et.

Beklenen sonuc:

- Hicbir tarama kaybolmamali.
- Aynı etiket iki kez eklenmediyse ayni urun iki kez olusmamali.
- Sonuclar farkli sirada gelse bile yanlis karta yazilmamali.
- Pending urunler kesin toplama dahil edilmemeli.

## 4. Internet Kapali Testi

1. Yeni alisveris baslat.
2. Cihazin internet baglantisini kapat.
3. Bir etiket tara.
4. Sepette urunun analiz durumunu izle.
5. Local parser sonucu gelirse urunun `Sonucu kontrol edin` benzeri bir durumda kaldigini kontrol et.

Beklenen sonuc:

- Uygulama cokmemeli.
- Urun sepette kalmali.
- Offline/local sonuc kesin sonuc gibi sessizce kabul edilmemeli.
- Kullanici manuel kontrol gerektigini anlayabilmeli.

## 5. Uygulamayi Kapatip Acma Testi

1. Yeni alisveris baslat.
2. Birden fazla etiketi tara.
3. Urunler `Sirada...` veya `Analiz ediliyor...` durumundayken uygulamayi tamamen kapat.
4. Uygulamayi yeniden ac.
5. Devam eden alisverisi ac.
6. Bekleyen urunlerin tekrar isleme alinip alinmadigini kontrol et.

Beklenen sonuc:

- Gecici urunler kaybolmamali.
- Kaydedilen fotograf yolu bozulmamali.
- `processing` durumunda kalmis urunler yeniden kuyruğa alinmali.
- Ayni sonuc iki kez yeni urun olarak eklenmemeli.

## 6. Sepet ve Toplam Testi

1. Bir tamamlanmis urun ve bir bekleyen urun olacak sekilde test yap.
2. Sepette toplam tutari kontrol et.
3. Bekleyen urun varken `Alisverisi Bitir` butonunu kontrol et.

Beklenen sonuc:

- Toplam tutar yalnizca `completed` urunlerden hesaplanmali.
- Bekleyen, basarisiz veya inceleme gereken urun varken alisveris bitirme pasif olmali.
- Kullanici eksik toplamla alisverisi yanlislikla bitirememeli.

## 7. Hata Durumu Testi

1. Cok bulanik veya bos bir goruntu tara.
2. Uygulamanin hata durumunu nasil gosterdigini kontrol et.

Beklenen sonuc:

- Uygulama cokmemeli.
- Urun sonsuza kadar `Analiz ediliyor...` durumunda kalmamali.
- Hata mesaji sepette gorunmeli.

## 8. Sonuclari Not Et

Her test icin su bilgileri not et:

- Test tarihi
- Cihaz veya simulator modeli
- Internet durumu
- Taratilan urun sayisi
- Basarili urun sayisi
- Yanlis fiyat sayisi
- Yanlis marka sayisi
- Kaybolan tarama var mi
- Yanlis karta yazilan sonuc var mi
- Sonsuz loading var mi
- Ekran goruntusu veya kisa video var mi

## 9. Hata Raporu Formati

Bir sorun bulursan su formatta kaydet:

```text
Baslik:

Adimlar:
1.
2.
3.

Beklenen:

Gerceklesen:

Cihaz:

Internet:

Ekran goruntusu/video:

Notlar:
```

## 10. Testten Sonra Kod Tarafinda Yapilacaklar

Testlerden sonra gelistirme tarafinda siradaki teknik isler:

- `AIResultValidator` eklemek.
- `needsReview` urunleri manuel duzenleme/onaylama ekranina baglamak.
- `failed` urunler icin yeniden dene ve manuel giris akislarini eklemek.
- SwiftData icin explicit migration planini degerlendirmek.
- Gercek etiketlerden basari/fiyat dogruluk oranlarini olcmek.
- Backend/API anahtari guvenligi icin Asema 8 planina gecmek.
