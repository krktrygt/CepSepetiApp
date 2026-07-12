CepSepeti Asenkron AI Tarama Sistemi Uygulama Planı

1. Amaç

CepSepeti uygulamasında kullanıcı raf etiketini taradıktan sonra AI sonucunu beklemek zorunda kalmamalıdır.

Yeni sistemde kullanıcı:

1. Raf etiketinin fotoğrafını çeker.
2. Ürün sepete hemen geçici olarak eklenir.
3. Ürün kartında Ekleniyor... veya Analiz ediliyor... durumu gösterilir.
4. Kullanıcı diğer ürünleri taramaya devam eder.
5. Taramalar kalıcı bir işlem kuyruğuna alınır.
6. AI sonucu geldiğinde ilgili ürün otomatik güncellenir.
7. Başarısız sonuçlar yeniden denenebilir veya manuel düzenlenebilir.

Temel hedef:

API gecikmesini kullanıcı akışını durdurmayan arka plan işlemi haline getirmek.

⸻

2. Yeni Sistem Özeti

Önerilen genel akış:

Kullanıcı fotoğraf çeker
        ↓
Fotoğraf yerel olarak kaydedilir
        ↓
Geçici ShoppingItem oluşturulur
status = queued
        ↓
Ürün sepette hemen görünür
        ↓
İşlem kuyruğuna eklenir
        ↓
Apple Vision OCR çalışır
        ↓
Local parser ön tahmin üretir
        ↓
Gemini veya backend isteği gönderilir
        ↓
Sonuç doğrulanır
        ↓
ShoppingItem güncellenir
        ↓
status = completed / needsReview / failed

Local parser nihai karar mekanizması olmayacaktır.

Local sistemin görevleri:

* OCR metnini temizlemek
* Hızlı ön tahmin üretmek
* Fiyat adaylarını bulmak
* Marka adaylarını bulmak
* İnternet olmadığında geçici offline sonuç sağlamak
* API isteği için ek bağlam üretmek

AI sisteminin görevi:

* Raf etiketini anlamlandırmak
* Satış fiyatını diğer sayılardan ayırmak
* Ürün adı ve markayı belirlemek
* Yerel tahmini doğrulamak veya düzeltmek

⸻

3. Temel Teknik Kararlar

3.1. AI fallback olmaktan çıkarılacak

Mevcut sistem:

Local parser
    ↓
Güven yüksekse kabul
    ↓
Güven düşükse Gemini

Yeni sistem:

Local parser hızlı tahmin üretir
        +
AI nihai sonucu üretir

Local parser’ın ürettiği güven skoru, AI çağrısı yapılıp yapılmayacağını belirlememelidir.

İnternet bağlantısı varsa AI doğrulaması varsayılan davranış olmalıdır.

⸻

3.2. Kullanıcı AI sonucunu beklemeyecek

Fotoğraf çekildiği anda geçici ürün oluşturulacaktır.

Örnek ürün kartı:

Analiz ediliyor...
Etiket tarandı: 14:32

Local sonuç hazırsa:

Doğrulanıyor...
Tahmini ürün: Sleepy Kişisel Bakım Havlusu
Tahmini fiyat: 39,00 TL

AI sonucu geldiğinde:

Sleepy Kişisel Bakım Havlusu Floral 25'li
Sleepy
39,00 TL
Doğrulandı

⸻

3.3. Kuyruk kalıcı olacak

Kuyruk yalnızca RAM içinde tutulmamalıdır.

Her tarama önce SwiftData içine kaydedilmelidir.

Uygulama kapanırsa veya işletim sistemi işlemi durdurursa, yeniden açılışta tamamlanmamış işler tekrar kuyruğa alınmalıdır.

Kalıcı durumlar:

enum ItemProcessingStatus: String, Codable {
    case queued
    case processing
    case completed
    case needsReview
    case failed
}

⸻

3.4. Aynı anda sınırlı sayıda işlem yapılacak

Tüm API istekleri tek tek sırayla çalıştırılmamalıdır.

Aynı anda önerilen maksimum işlem sayısı:

2

Neden:

* Tek işlem çok yavaş olabilir.
* Tam paralellik API limitlerini ve mobil bağlantıyı zorlayabilir.
* İki paralel iş, hız ve kontrol arasında dengelidir.

Bu sayı ileride yapılandırılabilir hale getirilebilir.

⸻

4. Veri Modeli Değişiklikleri

4.1. ShoppingItem genişletilecek

ShoppingItem şu alanları desteklemelidir:

var processingStatusRaw: String
var scanJobID: UUID?
var capturedImagePath: String?
var rawOCRText: String?
var localProductName: String?
var localBrand: String?
var localPrice: Double?
var aiConfidence: Double?
var processingError: String?
var retryCount: Int
var createdAt: Date
var processingStartedAt: Date?
var processingCompletedAt: Date?

Computed property:

var processingStatus: ItemProcessingStatus {
    get {
        ItemProcessingStatus(rawValue: processingStatusRaw) ?? .failed
    }
    set {
        processingStatusRaw = newValue.rawValue
    }
}

Mevcut alanlar korunmalıdır:

productName
brand
price
quantity
session

⸻

4.2. Geçici ürün desteği

Geçici ürün oluşturulurken:

productName = ""
brand = ""
price = 0
processingStatus = queued

Ancak UI boş alanları doğrudan göstermemelidir.

Geçici kart, işleme durumuna göre özel görünmelidir.

⸻

4.3. Marka kaydetme hatası düzeltilecek

OCR veya AI sonucunda gelen brand alanı mutlaka ShoppingItem.brand içine kaydedilmelidir.

Özellikle AddItemViewModel içinde ürün oluşturulurken marka alanının atlanmadığı doğrulanmalıdır.

Kabul kriteri:

AI sonucu brand = "Sleepy" ise,
ShoppingItem.brand değeri de "Sleepy" olmalıdır.

⸻

5. Yeni Servisler

5.1. ScanJob

Yeni bir iş modeli oluşturulmalıdır.

struct ScanJob: Identifiable, Sendable {
    let id: UUID
    let shoppingItemID: PersistentIdentifier
    let imagePath: String
    let createdAt: Date
}

Gerekirse SwiftData PersistentIdentifier yerine ayrı bir UUID alanı kullanılabilir.

Önerilen daha güvenli yaklaşım:

ShoppingItem.scanJobID

İş sonuçları bu ID üzerinden eşleştirilmelidir.

⸻

5.2. ScanProcessingQueue

Yeni dosya:

Services/ScanProcessingQueue.swift

Sorumlulukları:

* Yeni tarama işlerini kuyruğa almak
* Aynı anda en fazla iki işi çalıştırmak
* İş tamamlanınca sıradaki işi başlatmak
* Aynı işi iki kez çalıştırmamak
* Uygulama açıldığında yarım kalan işleri yeniden yüklemek
* İş durumlarını güncellemek

Önerilen yapı:

actor ScanProcessingQueue

Temel arayüz:

func enqueue(itemID: UUID)
func restorePendingJobs()
func retry(itemID: UUID)
func cancel(itemID: UUID)

Actor doğrudan SwiftData context kullanmamalıdır.

SwiftData işlemleri @MainActor üzerinde ayrı bir repository veya coordinator üzerinden yürütülmelidir.

⸻

5.3. ScanProcessingCoordinator

Yeni dosya:

Services/ScanProcessingCoordinator.swift

Sorumlulukları:

* Kuyruk ile SwiftData arasında köprü kurmak
* İşlem durumunu güncellemek
* Pipeline sonucunu ilgili ürüne yazmak
* Hataları kaydetmek
* UI yenilenmesini sağlamak

Önerilen yapı:

@MainActor
final class ScanProcessingCoordinator: ObservableObject

Temel işlevler:

func submitScan(image: UIImage, session: ShoppingSession)
func processItem(_ itemID: UUID)
func retryItem(_ itemID: UUID)
func restorePendingItems()

⸻

5.4. ImageProcessingPipeline yeniden düzenlenecek

Mevcut ImageProcessingPipeline doğrudan sonuç döndürmeye devam edebilir ancak karar akışı değiştirilmelidir.

Yeni pipeline:

1. Görseli hazırla
2. Vision OCR çalıştır
3. Local parser sonucu üret
4. İnternet kontrolü yap
5. İnternet varsa AI isteği gönder
6. AI sonucunu doğrula
7. Nihai sonucu döndür
8. OCRLog kaydı üret

Önerilen sonuç modeli:

struct ScanProcessingResult: Sendable {
    let productName: String
    let brand: String
    let price: Double
    let rawOCRText: String
    let localResult: ParsedLabelResult?
    let source: ResultSource
    let confidence: Double
    let needsReview: Bool
}

Kaynak türü:

enum ResultSource: String, Codable {
    case ai
    case localOffline
    case manual
}

⸻

6. AI İstek Yapısı

6.1. API’ye gönderilecek veriler

AI isteği şu verileri içermelidir:

* Kırpılmış raf etiketi görseli
* Vision OCR ham metni
* Local parser ürün tahmini
* Local parser marka tahmini
* Local parser fiyat adayları
* Market tahmini
* Açık görev talimatı

Gönderilmemesi gerekenler:

* Tam çözünürlüklü kamera fotoğrafı
* Gereksiz debug metinleri
* Kullanıcının geçmiş alışveriş verileri
* Başka ürünlere ait bilgiler

⸻

6.2. Görsel optimizasyonu

API’ye gönderilmeden önce görsel:

1. Etiket bölgesine kırpılmalı
2. Yönü düzeltilmeli
3. En uzun kenarı yaklaşık 1200-1600 piksele küçültülmeli
4. JPEG formatında sıkıştırılmalı
5. Dosya boyutu mümkünse birkaç yüz KB seviyesine indirilmelidir

Kabul kriteri:

API’ye orijinal kamera çözünürlüğü gönderilmemelidir.

⸻

6.3. Zorunlu JSON çıktısı

AI serbest metin döndürmemelidir.

Beklenen çıktı:

{
  "productName": "Sleepy Kişisel Bakım Havlusu Floral 25'li",
  "brand": "Sleepy",
  "price": 39.0,
  "currency": "TRY",
  "confidence": 0.98,
  "needsUserReview": false
}

Kurallar:

* price, ürünün satış fiyatı olmalıdır.
* Birim fiyat seçilmemelidir.
* Tarih fiyat olarak seçilmemelidir.
* Ürün kodu fiyat olarak seçilmemelidir.
* Kampanya varsa kasada ödenecek geçerli fiyat tercih edilmelidir.
* Emin olunamıyorsa needsUserReview = true olmalıdır.

⸻

7. Sonuç Doğrulama

AI çıktısı doğrudan kabul edilmemelidir.

Yeni bir doğrulama katmanı oluşturulmalıdır.

Yeni dosya:

Services/Parsing/AIResultValidator.swift

Kontroller:

* Fiyat sıfırdan büyük mü?
* Fiyat makul bir aralıkta mı?
* Ürün adı boş mu?
* Ürün adı yalnızca rakamlardan mı oluşuyor?
* AI fiyatı OCR metninde veya görsel bağlamında destekleniyor mu?
* Fiyat tarih formatına benziyor mu?
* Fiyat ürün koduna benziyor mu?
* Marka alanı ürün adıyla çelişiyor mu?
* Local sonuç ile AI sonucu aşırı farklı mı?

Örnek:

struct ValidationResult {
    let isValid: Bool
    let needsReview: Bool
    let warnings: [String]
}

AI tarafından verilen confidence değeri tek başına karar vermemelidir.

⸻

8. Sepet Arayüzü

8.1. Ürün kartı durumları

queued

Sırada...
Etiket işleme kuyruğuna alındı.

processing

Analiz ediliyor...

completed

Ürün adı
Marka
Fiyat

needsReview

Sonucu kontrol edin
Ürün adı
Marka
Fiyat
[Düzenle] [Onayla]

failed

Ürün analiz edilemedi
[Yeniden Dene] [Manuel Gir] [Sil]

⸻

8.2. Toplam fiyat davranışı

Varsayılan olarak yalnızca tamamlanmış ürünler kesin toplama dahil edilmelidir.

Örnek:

Kesin Toplam: 184,50 TL
2 ürün analiz ediliyor

Local tahmin gösterilecekse ayrı bir değer olarak verilmelidir:

Tahmini Toplam: 263,50 TL
Kesinleşen Toplam: 184,50 TL

Tahmini ve kesin toplam birbirine karıştırılmamalıdır.

⸻

8.3. Alışverişi bitirme davranışı

Bekleyen ürün varken kullanıcı alışverişi bitirmeye çalışırsa uyarı gösterilmelidir.

Örnek:

2 ürün henüz analiz edilmedi.
Gösterilen toplam eksik olabilir.

Seçenekler:

Analizlerin Bitmesini Bekle
Ürünleri Manuel Tamamla
Alışverişe Geri Dön

Başarısız veya incelenmemiş ürünler sessizce geçmiş alışverişe kaydedilmemelidir.

⸻

9. Uygulama Yaşam Döngüsü

9.1. Uygulama kapanırsa

queued ve processing durumundaki ürünler SwiftData içinde kalmalıdır.

Uygulama yeniden açıldığında:

queued → tekrar kuyruğa ekle
processing → interrupted kabul et ve tekrar kuyruğa ekle

processing durumunda kalmış ancak aktif task bulunmayan ürünler otomatik olarak yeniden denenmelidir.

⸻

9.2. Uygulama arka plana giderse

Normal Swift Task işlemlerinin kesilebileceği kabul edilmelidir.

Sistem şu varsayımla tasarlanmalıdır:

Her ağ isteği yarıda kesilebilir ve uygulama daha sonra yeniden açılabilir.

Bu nedenle:

* İş önceden SwiftData’ya kaydedilmeli
* Fotoğraf yerel dosyada bulunmalı
* İş benzersiz ID taşımalı
* Tekrar çalıştırma güvenli olmalı
* Aynı sonuç iki kez ürün eklememeli

⸻

10. Retry Politikası

Otomatik tekrar sayısı:

Maksimum 2 otomatik retry

Önerilen sıra:

İlk deneme: hemen
İkinci deneme: kısa gecikme sonrası
Üçüncü deneme: kullanıcı isteğiyle

Retry yapılacak durumlar:

* Timeout
* Geçici ağ hatası
* Sunucu 5xx hatası
* Bağlantı kesilmesi

Retry yapılmaması gereken durumlar:

* Geçersiz API anahtarı
* Kalıcı yetkilendirme hatası
* Bozuk görsel
* Desteklenmeyen yanıt
* Kullanıcı işi iptal ettiyse

⸻

11. Güvenlik

11.1. API anahtarı uygulama içinde tutulmamalı

Secrets.plist içine konulan API anahtarı dağıtım için güvenli değildir.

Üretim yapısı:

iOS uygulaması
    ↓
CepSepeti backend
    ↓
Gemini API

Backend görevleri:

* Gemini API anahtarını saklamak
* Kullanıcı başına rate limit uygulamak
* Günlük kullanım sınırı koymak
* İstek boyutunu sınırlandırmak
* Model ve prompt yönetmek
* Hata loglamak
* Kötüye kullanımı engellemek

Geliştirme aşamasında doğrudan API kullanılabilir ancak üretim öncesi backend zorunludur.

⸻

12. brands.json Düzeltmesi

brands.json dosyasının Xcode target resource listesine eklendiği doğrulanmalıdır.

Kontrol:

Bundle.main.url(
    forResource: "brands",
    withExtension: "json"
)

Değer nil olmamalıdır.

Kabul kriteri:

Gerçek cihaz ve simülatörde BrandDatabase başarıyla yüklenmelidir.

⸻

13. Uygulama Aşamaları

Aşama 1: Kritik mevcut hataları düzelt

Görevler:

* brands.json target resource içine ekle
* OCR sonucundaki brand alanını ShoppingItem içine kaydet
* Mevcut pipeline davranışını belgeleyip test et
* Kirli çalışma ağacını incele
* Kullanıcı değişikliklerine dokunma
* Mevcut parser testlerini çalıştır

Tamamlanma kriteri:

Mevcut özellikler kırılmadan marka verisi doğru kaydediliyor.

⸻

Aşama 2: Processing status ekle

Görevler:

* ItemProcessingStatus oluştur
* ShoppingItem modelini genişlet
* SwiftData migration gereksinimini kontrol et
* Geçici ürün oluşturma desteği ekle
* Sepette status bazlı kart göster

Tamamlanma kriteri:

Bir ürün completed olmadan sepette queued ve processing olarak gösterilebiliyor.

⸻

Aşama 3: Fotoğrafı anında sepete ekle

Görevler:

* Fotoğraf çekildiğinde geçici ShoppingItem oluştur
* Fotoğrafı uygulamanın yerel storage alanına kaydet
* Kullanıcıyı sonuç ekranında bekletme
* Kamera tekrar taramaya hazır hale gelsin
* Geçici ürün sepette görünsün

Tamamlanma kriteri:

Kullanıcı ilk taramanın sonucu gelmeden ikinci ürünü tarayabiliyor.

⸻

Aşama 4: Kalıcı kuyruk sistemi

Görevler:

* ScanProcessingQueue oluştur
* ScanProcessingCoordinator oluştur
* Aynı anda maksimum iki iş çalıştır
* İşleri ID ile eşleştir
* Tamamlanınca ilgili ürünü güncelle
* Uygulama açılışında yarım işleri geri yükle

Tamamlanma kriteri:

Beş ürün hızlıca tarandığında hepsi kaybolmadan sıraya giriyor ve sonuçlar doğru kartlara yazılıyor.

⸻

Aşama 5: AI merkezli pipeline

Görevler:

* Local güven skoru kapısını kaldır
* İnternet varsa AI doğrulamasını varsayılan yap
* Local parser’ı ön tahmin rolüne geçir
* AI isteğine görsel, OCR ve local adayları ekle
* JSON çıktı zorunlu hale getir
* AI sonucu parse et

Tamamlanma kriteri:

İnternet varken her geçerli tarama AI tarafından doğrulanıyor.

⸻

Aşama 6: Validator ve hata yönetimi

Görevler:

* AIResultValidator oluştur
* Geçersiz fiyatları yakala
* needsReview durumunu uygula
* Retry sistemi ekle
* Manuel giriş seçeneği ekle
* Başarısız ürünlerde sonsuz spinner oluşmasını engelle

Tamamlanma kriteri:

Her iş completed, needsReview veya failed durumlarından biriyle sonlanıyor.

⸻

Aşama 7: Toplam ve alışveriş bitirme

Görevler:

* Kesin toplamı yalnızca completed ürünlerden hesapla
* Bekleyen ürün sayısını göster
* Gerekirse tahmini toplamı ayrı göster
* Pending ürün varken bitirme uyarısı ekle
* needsReview ürünler için onay akışı ekle

Tamamlanma kriteri:

Kullanıcı kasaya gitmeden önce hangi ürünlerin kesinleştiğini net biçimde görebiliyor.

⸻

Aşama 8: Backend ve güvenlik

Görevler:

* Gemini çağrısı için backend endpoint oluştur
* API anahtarını istemciden kaldır
* Rate limit ekle
* Timeout ve hata formatı belirle
* İstek ve yanıt şemasını sabitle
* Gerekirse cihaz veya kullanıcı bazlı limit uygula

Tamamlanma kriteri:

Üretim uygulamasının bundle’ında Gemini API anahtarı bulunmuyor.

⸻

Aşama 9: Test ve optimizasyon

Görevler:

* Gerçek market etiketleriyle test et
* Aynı anda çoklu tarama testi yap
* Ağ kesilme testi yap
* Uygulamayı kapatıp açma testi yap
* Retry testi yap
* Yanlış sırada tamamlanan istekleri test et
* Görsel boyutunu optimize et
* Ortalama API süresini ölç
* Başarı oranını ölç

Hedef metrikler:

Ürün doğruluğu: en az %95
Fiyat doğruluğu: en az %98
İlk taramadan sonra kamera tekrar kullanılabilirlik: 1-2 saniye
Kayıp tarama: %0
Yanlış ürüne yazılan sonuç: %0
Sonsuz processing durumu: %0

⸻

14. Test Senaryoları

Test 1: Tek ürün

1. Bir etiket tara.
2. Ürün hemen queued olarak görünmeli.
3. Processing durumuna geçmeli.
4. Sonuç geldiğinde completed olmalı.
5. Toplam güncellenmeli.

⸻

Test 2: Art arda beş ürün

1. Beş etiketi hızlıca tara.
2. Kullanıcı her taramadan sonra kamerayı yeniden kullanabilmeli.
3. Beş geçici kart sepette görünmeli.
4. Aynı anda en fazla iki API işi çalışmalı.
5. Sonuçlar doğru kartlara yazılmalı.

⸻

Test 3: Sonuçların farklı sırada gelmesi

1. Ürün A ve B taransın.
2. B sonucu önce gelsin.
3. B sonucu B kartına yazılmalı.
4. A sonucu daha sonra A kartına yazılmalı.

⸻

Test 4: İnternet kesilmesi

1. Ürün tara.
2. API çağrısı sırasında interneti kapat.
3. Ürün failed veya yeniden denenebilir duruma geçmeli.
4. İnternet açılınca retry yapılabilmeli.
5. Aynı ürün iki kez eklenmemeli.

⸻

Test 5: Uygulamayı kapatma

1. Ürünleri tara.
2. İşlem devam ederken uygulamayı tamamen kapat.
3. Uygulamayı yeniden aç.
4. Yarım kalan ürünler tekrar kuyruğa alınmalı.
5. Fotoğraflar kaybolmamalı.

⸻

Test 6: Geçersiz AI yanıtı

1. Eksik JSON sonucu simüle et.
2. Ürün completed olmamalı.
3. needsReview veya failed olmalı.
4. Kullanıcı manuel giriş yapabilmeli.

⸻

Test 7: Alışverişi erken bitirme

1. Birkaç ürün tara.
2. Sonuçlar gelmeden alışverişi bitirmeye çalış.
3. Bekleyen ürün uyarısı gösterilmeli.
4. Kullanıcı eksik toplamla yanlışlıkla devam etmemeli.

⸻

15. Agent Çalışma Kuralları

Agent aşağıdaki kurallara uymalıdır:

1. Mevcut dosyaları incelemeden değişiklik yapma.
2. Kullanıcının mevcut çalışma ağacındaki değişikliklerini silme.
3. Kullanıcı tarafından değiştirilmiş dosyaları otomatik geri alma.
4. Büyük refactor yerine küçük ve test edilebilir adımlarla ilerle.
5. Her aşamada değiştirdiğin dosyaları listele.
6. Her aşamada neden değişiklik yaptığını açıkla.
7. Yeni dependency eklemeden önce gerekçesini belirt.
8. SwiftData model değişikliklerinde migration riskini değerlendir.
9. MainActor ve Sendable uyarılarını görmezden gelme.
10. Kamera, OCR ve mevcut parser davranışını gereksiz yere yeniden yazma.
11. Mevcut testleri silme veya testleri geçsin diye zayıflatma.
12. API anahtarını kaynak kod içine yazma.
13. Her iş için benzersiz ID kullan.
14. API sonuçlarını liste sırasına göre eşleştirme.
15. Kuyruğu yalnızca RAM içinde tutma.
16. Sonsuz retry veya sonsuz loading durumu oluşturma.
17. Kullanıcının açık izni olmadan UI tasarımını baştan değiştirme.
18. Her aşamadan sonra build ve test sonucu raporla.
19. Build çalışmıyorsa hatayı açıkça yaz, çalışmış gibi davranma.
20. Bir aşama tamamlanmadan sonraki aşamaya geçme.

⸻

16. Agent İçin Başlangıç Promptu

CepSepetiApp projesinde asenkron ve kalıcı bir AI tarama kuyruğu oluşturacağız.

Önce projeyi analiz et. Henüz kod değiştirme.

Hedef sistem:

* Kullanıcı raf etiketi fotoğrafı çektikten sonra AI sonucunu beklemeyecek.
* Geçici ürün sepete hemen queued durumu ile eklenecek.
* Kullanıcı diğer ürünleri taramaya devam edebilecek.
* İşler kalıcı bir kuyruğa alınacak.
* Aynı anda en fazla iki iş çalışacak.
* Local parser yalnızca hızlı ön tahmin üretecek.
* İnternet varsa Gemini nihai doğrulama motoru olacak.
* Sonuç geldiğinde ilgili ShoppingItem benzersiz ID ile güncellenecek.
* Uygulama kapanıp açıldığında yarım kalan işler yeniden devam edecek.
* Başarısız işler retry veya manuel giriş sunacak.
* Pending ürünler kesin toplam içine dahil edilmeyecek.

İlk görev:

1. Mevcut ShoppingItem, AddItemViewModel, ImageProcessingPipeline, CameraService, OCRService, GeminiService ve sepet UI dosyalarını incele.
2. Mevcut veri akışını çıkar.
3. SwiftData migration riskini değerlendir.
4. Yeni sistem için değiştirilmesi gereken dosyaları listele.
5. Yeni oluşturulması gereken dosyaları listele.
6. Mevcut kullanıcı değişikliklerine dokunma.
7. Henüz kod yazma.
8. Yalnızca analiz ve uygulanabilir ilk aşama planı üret.

Analiz sonunda özellikle şu riskleri kontrol et:

* brands.json bundle resource durumu
* ShoppingItem oluşturulurken brand alanının kaydedilmesi
* SwiftData context’in actor içinden kullanılması
* MainActor izolasyonu
* Görsellerin nerede ve nasıl saklanacağı
* Uygulama kapanınca yarım kalan taskların durumu
* Aynı işin iki kez işlenme ihtimali
* API sonucunun yanlış ShoppingItem’a yazılma ihtimali
* Mevcut kirli çalışma ağacındaki dosyalar
* API anahtarının Secrets.plist içinde bulunması

Kod yazmadan önce bulguları raporla.

⸻

17. İlk Uygulama Görevi

Analiz tamamlandıktan sonra yalnızca Aşama 1 uygulanmalıdır.

Aşama 1 kapsamı:

* brands.json resource entegrasyonunu düzelt
* ShoppingItem oluşturulurken brand alanının kaydedildiğini garanti et
* Mevcut parser testlerini koru
* Yeni sistem için henüz kuyruk veya model değişikliği yapma
* Değiştirilen dosyaları raporla
* Build veya test çalıştır
* Çalıştırılamazsa gerçek nedeni yaz

Aşama 1 kabul edilmeden Aşama 2’ye geçme.

⸻

18. Kapsam Dışı Konular

Bu çalışmada şimdilik yapılmayacaklar:

* Tüm uygulama UI’ını yeniden tasarlamak
* SwiftData modellerini tamamen yeniden kurmak
* Apple Vision OCR’ı kaldırmak
* Local parser’ı silmek
* Brand database sistemini kaldırmak
* İstatistik ekranını yeniden yazmak
* Kullanıcı hesabı sistemi eklemek
* Abonelik sistemi eklemek
* App Store ödeme entegrasyonu
* Gelişmiş analitik paneli
* Görsel tanıma için özel ML modeli eğitmek
* Tüm geçmiş OCR kayıtlarını backend’e yüklemek

⸻

19. Nihai Başarı Tanımı

Sistem tamamlandığında kullanıcı deneyimi şu şekilde olmalıdır:

1. Kullanıcı etiketi çeker.
2. Ürün sepette anında Analiz ediliyor... olarak görünür.
3. Kamera hemen yeni tarama için hazır olur.
4. Kullanıcı art arda ürün tarayabilir.
5. Uygulama işleri arka planda işler.
6. Sonuçlar geldikçe ürün kartları güncellenir.
7. Sepet toplamı otomatik kesinleşir.
8. Sorunlu ürünler kullanıcıya açık biçimde gösterilir.
9. Uygulama kapansa bile taramalar kaybolmaz.
10. API anahtarı uygulamanın içinde bulunmaz.
11. Local parser hızlı yardımcı katman olarak kalır.
12. AI sistemi nihai ürün ve fiyat seçimini yapar.