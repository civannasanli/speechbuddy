# Okuma Prototipi (Phonem AI) — Proje Bağlamı

## 1. Projenin Amacı

Flutter ile geliştirilen bir çocuk konuşma/telaffuz değerlendirme uygulaması. Çocuk ekrandaki bir resme dokunuyor, uygulama kelimeyi TTS ile okuyor, sonra 3 saniyelik ses kaydı alıyor. Kayıt, uzak bir sunucudaki (FastAPI + PyTorch) yapay zeka modeline yükleniyor. Model, telaffuzun patolojik olup olmadığını (`is_pathological`) ve olasılığını (`pathology_probability`) döndürüyor. Uygulama bu sonuca göre çocuğa geri bildirim veriyor.

**Sunucu:** `184.174.34.219:8008/predict` (Ubuntu 24.04 VPS, sip.com.tr üzerinde barındırılıyor — kullanıcı bilgisayarından bağımsız, sürekli açık). Model dosyası `best_model.pth`, backend kodu `inference.py` (FastAPI + `MultiTaskCNN`, mel-spektrogram + WebRTC VAD tabanlı ön işleme).

Backend/model tarafı **arkadaşımız İsmail'in** sorumluluğunda — bu proje sadece Flutter (mobil uygulama) tarafını kapsıyor.

## 2. Mimari Kararlar (Sırayla Alındı)

1. **`speech_to_text` (STT) tamamen kaldırıldı** — cihaz üstü konuşma tanıma yerine, ses kaydedilip sunucudaki modele gönderiliyor. `flutter_tts` (TTS) kaldırılmadı, hâlâ kelimeyi okumak için kullanılıyor.
2. **Yaş grubu seçimi kaldırıldı** — eskiden 3-4/4-5/5-6 yaş kategorisi vardı, şimdi direkt "Bölüm" listesi var.
3. **Ekranda 3 resim aynı anda** gösteriliyor (mikrofon butonu yok) — çocuk hangi resme dokunursa önce o kelime TTS ile okunuyor, sonra 3 saniyelik kayıt otomatik başlıyor.
4. **Dokunma sırası serbest** — çocuk 3 resimden istediğine istediği sırada dokunabilir.
5. **Retry mekanizması YOK** — model "yanlış" derse bile o an tekrar okutulmuyor, sonuç olduğu gibi kabul ediliyor. (Yanlış olanlar için ayrı bir "alıştırmalar" modülü ileride yapılacak, henüz konuşulmadı.)
6. **Batch analiz mantığı** — 3'lü grup tamamlanınca (3 kayıt bitince), 3 ses dosyası **arka planda paralel** olarak API'ye yükleniyor (bekletmeden). Bu sırada "Aferin, harikasın!" ekranı gösteriliyor, "Devam Et" butonuna basınca (analiz bitmiş olsun olmasın) bir sonraki 3'lüye geçiliyor. Bölümün **son** 3'lüsünde, final sonuç ekranına geçmeden önce bekleyen tüm analizlerin bitmesi bekleniyor (`Future.wait(pendingUploads)`).
7. **Veri yapısı**: Toplam 50 kelime, 6 bölüme ayrıldı — bölüm 1-5: 9'ar kelime (her biri 3 ekran × 3 kelime), bölüm 6: 5 kelime (3+2 ekran). *(Not: Bkz. Bölüm 4 — müşteri revizyonu bu sayıyı 24 kelimeye düşürüyor, henüz uygulanmadı.)*
8. **`_imageCard` görsel tasarımı**: İlk halinde beyaz kutu + border + shadow içinde `BoxFit.contain` resim vardı, kullanıcı bunu beğenmedi. **Son/doğru hal**: 170×170 boyutunda, çerçevesiz, `ClipRRect` + `BoxFit.cover` ile direkt resim gösteriliyor, durum (kayıtta/tamamlandı) resmin üstüne bindirilen ince kırmızı/yeşil çerçeveyle gösteriliyor.
9. **Balon geçiş animasyonu DENENDİ VE GERİ ALINDI** — sayfa geçişlerinde ve "Devam Et" sırasında balon animasyonu eklenmeye çalışıldı, çalıştırılamadı (kullanıcı sorun yaşadı), sonunda tüm balon kodu tamamen kaldırıldı, `MaterialPageRoute`'a geri dönüldü. **Bu özellik artık projede yok, tekrar eklenmesi istenirse sıfırdan ele alınmalı.**
10. **Model API çağrısı**: `http.MultipartRequest` ile `Config.apiUrl` (`http://184.174.34.219:8008/predict`) adresine `file` alanıyla multipart POST. Kabul edilen formatlar: `.wav .m4a .mp4 .amr .ogg .flac .mp3`.
11. **SharedPreferences ile ilerleme takibi**: `bolum${i}_stars`, `bolum${i}_completed` anahtarlarıyla bölüm bazlı yıldız/tamamlanma durumu saklanıyor. Bir bölüm tamamlanmadan bir sonraki kilitli kalıyor.
12. **Yıldız hesabı**: Retry olmadığı için, her doğru (`is_pathological == false`) kelime 3 yıldız değerinde sayılıyor, bölüm ortalaması alınıp yuvarlanıyor.

## 3. Mevcut Durum / Test Sürecinde Öğrenilenler

- Uygulama emülatörde (`sdk gphone16k x86 64`) çalıştırılıp test edildi, TTS ve kayıt akışı çalışıyor.
- Log'da bir kez `TextToSpeech: speak failed / DeadObjectException` görüldü — bu Android sistem TTS servisinin emülatörde geçici çökmesi/yeniden bağlanması, kod hatası değil. Sistem kendini toparlıyor. (İsteğe bağlı try/catch eklenmedi, "şimdilik gerek yok" denildi.)
- Android Studio'da ilk başta "New Project" sihirbazında Flutter seçeneği çıkmıyordu — **çözüm**: Settings → Plugins → Flutter eklentisini kur, IDE'yi yeniden başlat. Alternatif/daha garanti yöntem: terminalden `flutter create <isim>` ile proje oluşturup Android Studio'da "Open" ile açmak.
- SSH ile sunucuya bağlanma sürecinde `Permission denied (publickey)` hatası yaşandı — sebebi private key dosyasının Windows'ta yanlış kaydedilmesiydi (`-NoNewline` parametresi dosya sonundaki gerekli newline'ı siliyordu). PowerShell'de `Set-Content -Encoding ascii` (NoNewline OLMADAN) ile düzeltildi, bağlantı başarılı oldu (`ismail@vmi3200249`).
- Sunucuda `~/phonem_analiz/` klasöründe `Dockerfile`, `best_model.pth`, `inference.py`, `requirements.txt` bulundu.

## 4. Müşteri Revizyon Talepleri (Henüz Uygulanmadı — Sıradaki İş)

Kaynak: `DEĞERLENDİRME MODÜLÜ GELİŞTİRME TALEPLERİ.docx` + toplantı sunumu (BİGG TOPLANTI SUNUMU.pptx) ekran görüntüleri + kelime listesi görselleri (DİLART Mobil Uygulama Değerlendirme Modülü)

### 4.1 Backend/Altyapı tarafı (bizi ilgilendirmiyor, İsmail'in konusu)
- Yapay zeka analiz süresinin hızlandırılması — cloud altyapıya geçiş.
- Mevcut model performans sorunları: yanlış pozitif/negatif sonuçlar, ~10 dakikaya varan analiz süresi, "analiz edilemedi" hataları.

### 4.2 Flutter/UI tarafı (bizim işimiz)

**A) Kelime listesi tamamen değişiyor: 50 → 24 kelime**

EK-1'deki liste (görsellerden çıkarılan tam grup + görsel eşleşmesi, turuncu çerçeveli slaytlarda verildi, 8 ekran × 3 kelime = 24):
Ekran 1: peynir, elma, bardak
Ekran 2: yatak, dondurma, ayakkabı
Ekran 3: bayrak, güneş, havuç
Ekran 4: anahtar, limon, bisiklet
Ekran 5: sabun, üzüm, şapka
Ekran 6: kaşık, çocuk, yılan
Ekran 7: salıncak, vazo, fırça
Ekran 8: jilet, ruj, telefon
Not: Bu 24 kelimenin görsel dosyaları (şeffaf arka planlı, üzerinde yazı olmayan orijinal PNG) müşterinin Google Drive linkinde — Claude'un bu linke erişimi yok, Civan indirip tek tek Claude'a (ya da Claude Code'a) göndermesi gerekiyor. Şimdilik elde sadece "kelime + kaba görsel önizleme" var (turuncu çerçeveli, üzerinde yazı basılı görsel — bunlar direkt asset olarak kullanılamaz, sadece referans).

**Aksiyon**: `AppWords` veri yapısı yeniden yazılmalı — mevcut 50 kelime/6 bölümlük yapı yerine, 24 kelime / 8 sabit 3'lü ekran (bölüm kavramı kalkabilir ya da 8 ekranı tek "bölüm" gibi ele alabiliriz — karara bağlanmadı, Claude Code'da konuşulmalı).

**B) Ekran/kelime geçişleri animasyonlu olmalı**
- "Balon ikonunun hareketlendirilmesiyle" geçiş isteniyor.
- **Bu proje kapsamında bir kez denendi (bkz. Bölüm 2, madde 9) ve teknik zorluk yaşanıp tamamen geri alındı.** Yeniden ele alınacaksa muhtemelen daha basit/garanti bir yöntemle (örn. hazır bir Lottie animasyonu, ya da çok daha basit bir `AnimatedSwitcher`/`SlideTransition`) denenmeli.

**C) Motive edici geri bildirimler**
- "Harika ilerliyorsun!", "Çok iyi!" gibi mesajlar. Şu an sadece bölüm sonunda tek bir "Aferin!" ekranı var — müşteri muhtemelen her doğru kelimede/daha sık geri bildirim istiyor. Netleştirilmesi gerekiyor.

**D) Canlı renk paleti**
- Şu anki açık mavi/yeşil (`Colors.lightBlue.shade50`, `Colors.green`) yerine, müşterinin gönderdiği örneklerdeki gibi turuncu/pembe/canlı tonlar isteniyor. Görsellerdeki "TEBRİKLER!" ekranı turuncu başlık + parti temalı hayvan illüstrasyonları kullanıyor.

**E) Maskot karakter eklenmesi**
- Müşteri bir "karakter referans sayfası" gönderdi: turuncu kedi, turkuaz kapüşonlu, çeşitli pozlarda (el sallama, gülümseme, başparmak, laptop başında, telefon, zıplama/kutlama). Bu görsel **muhtemelen AI (büyük ihtimalle Midjourney tarzı bir araç) ile üretilmiş bir konsept/mood board** — gerçek, şeffaf arka planlı, üretime hazır ayrı dosyalar değil. Doğrudan asset olarak kullanılamaz.
- Claude, aynı renk paletini (turuncu kedi, turkuaz hoodie) kullanan basit, düz vektör (SVG) bir alternatif tasarım denedi (Visualizer aracıyla, el sallayan poz) — kullanıcı onay vermeden "şimdilik placeholder kullanalım" kararı alındı.
- **Güncel durum (2026-08-08)**: Civan gerçek bir maskot görseli gönderdi (kahverengi/beyaz tüylü, pembe fiyonklu, patisiyle el sallayan sevimli kedi — turuncu kedi/turkuaz hoodie konseptinden farklı, ama artık gerçek bir karakter var). `assets/maskot/maskot.png` olarak eklendi (şeffaf arka plan, hafif ışıltı/glow efekti dahil). Şimdilik sadece `HomePage`'deki eski uyumsuz yeşil papağan (`parrot.png`) bununla değiştirildi. **Henüz yapılmadı**: Civan "çocuğu menüler boyunca yönlendiren bir karakter" istiyor — yani maskotun konuşma balonlarıyla ipucu vermesi/rehberlik etmesi gibi daha kapsamlı bir sistem isteniyor, ama "sonra bakarız ne olacağına" dendiği için detaylandırılmadı, bir sonraki konuşmada ele alınmalı.

**F) Değerlendirme + terapi modülü için ortak etkileşimli arayüz**
- Büyük kapsamlı bir talep, referans olarak Speech Blubs / Duolingo Kids / DinoLingo gibi uygulamalar gösterilmiş. Şu an sadece "değerlendirme" (assessment) tarafı var, "terapi" modülü hiç yok — bu ayrı bir epik, henüz hiç ele alınmadı.

## 5. Kod

Güncel kod her zaman `lib/main.dart` içinde — burada ayrıca kopyası tutulmuyor (senkron kalması zor, gereksiz şişkinlik). Bir önceki halin nasıl olduğunu görmek gerekirse `git log -p -- lib/main.dart` yeterli.

## 6. Sıradaki Adımlar (Öncelik Sırasız — Claude Code'da Konuşulmalı)

**Not (2026-08-07):** Civan, 24 kelimelik liste entegrasyonunu (eski madde 1) şimdilik tamamen gündemden kaldırdı — "yok gibi düşün" denildi, tekrar gündeme gelmedikçe ele alınmayacak. Maskot karakteri de (eski madde 4) Civan gerçek asset'leri getirene kadar beklemede — vektör alternatif tasarım denenmeyecek, statik entegrasyon planı da yapılmayacak.

1. ~~Müşterinin 24 kelimelik yeni listesini entegre etmek~~ — **iptal, gündemde değil.**
2. ~~Renk paletini müşterinin istediği canlı tonlara (turuncu/pembe ağırlıklı) çevirmek~~ — **tamamlandı** (bkz. Bölüm 8).
3. ~~Motive edici geri bildirim sıklığını/çeşitliliğini artırmak~~ — **tamamlandı** (bkz. Bölüm 9).
4. Maskot karakteri — **beklemede**, Civan gerçek asset getirene kadar dokunulmayacak.
5. "Alıştırmalar" (yanlış okunan kelimeler için tekrar) modülü — henüz tasarlanmadı.
6. Terapi modülü — kapsamı büyük, ayrı bir epik olarak ele alınmalı.

## 8. Renk Paleti Değişikliği (2026-08-07, Tamamlandı)

`lib/main.dart` içine `AppColors` sınıfı eklendi:
- `primary` = `0xFFFF7A3D` (canlı turuncu) — app bar'lar, ana butonlar, kilitli olmayan bölüm ikonu, ilerleme göstergesi.
- `primaryDark` = `0xFFE8611F` (şu an tanımlı ama kullanılmıyor, ileride hover/pressed state için).
- `secondary` = `0xFFFF4D8D` (canlı pembe) — "Aferin!" başlığı, "Harika, Tamamladın!" başlığı (vurgu metinleri).
- `background` = `0xFFFFF1E6` (sıcak krem) — tüm sayfa arka planları (eskiden `Colors.lightBlue.shade50` / `Colors.lightGreen.shade100`).
- `surfaceLight` = `0xFFFFDCC2` (açık turuncu) — bölüm listesinde kilitli olmayan ikon zemini.

**Bilinçli olarak DEĞİŞTİRİLMEYEN yerler** (semantik anlamları olduğu için): doğru/yanlış telaffuz göstergeleri (`is_pathological` sonucuna göre yeşil/kırmızı — final sonuç listesi, resim kartındaki "tamamlandı" yeşil çerçeve/tik), yıldızlar (`Colors.amber`), kilitli bölüm ikonları (`Colors.grey`).

## 9. Kelime Başına Sesli Geri Bildirim (2026-08-07, Tamamlandı)

Her kelime kaydı bitince (model sonucu beklenmeden — analiz dakikalar sürebiliyor, bu yüzden anlık genel teşvik tercih edildi), `_tts` rastgele bir teşvik cümlesi söylüyor: `Harikasın!`, `Çok iyi!`, `Süpersin!`, `Çok güzel okudun!`, `Bravo!`, `Aferin sana!` (`_encouragements` listesi, `_BolumPlayPageState` içinde). Doğru/yanlış ayrımı yapılmıyor, sadece motivasyon. 3'lü bitince gösterilen mevcut "Aferin!" ekranı (görsel + konfeti) olduğu gibi korundu, buna ek bir katman.

Sesin çalınıp çalınmayacağı (`soundEnabled`) ve hızı (`ttsSpeed`) ayarlar sayfasındaki mevcut TTS ayarlarına bağlı — ayrı bir ayar eklenmedi.

## 10. Balon/Kedi Geçiş Animasyonu (2026-08-07, Tamamlandı — 2 aşamada geliştirildi)

**Önceki deneme** (bkz. Bölüm 2, madde 9) sayfa geçiş/route mantığına gömülmeye çalışılmış ve başarısız olmuştu. **Bu sefer** animasyon Navigator'dan tamamen bağımsız, `BolumPlayPage` içindeki `stage` state makinesinin bir parçası olarak kuruldu — aynı hataya düşme riski düşük.

- **Kaynak/Asset**: Civan LottieFiles'tan bir animasyon indirdi (`.lottie` / dotLottie formatı). `assets/lottie/balon.lottie` olarak projeye eklendi. Animasyonun layer isimleri (`tail`, `meow`, `L hand`/`R hand`/`L leg`/`R leg`, `balloon 4/7/8`) incelendiğinde bunun **balonlu bir kedi** animasyonu olduğu anlaşıldı — ayrıca bir kedi asset'i aramaya gerek kalmadı, aynı dosya hem "balon" hem "kedi" isteğini karşılıyor.
- **Paket**: `lottie: ^3.1.3` (pub get sonrası 3.5.1 çözüldü) — `.lottie` formatını doğrudan destekliyor.

**Nihai akış (kullanıcı talebiyle revize edildi — ilk halinde balon sadece "Aferin!" ekranının içinde sabit yerde oynuyordu, bu yetersiz bulundu):**

1. 3'lü grup bitince "Aferin! Muhteşemsin!" ekranı (konfeti + sesli teşvik) **statik olarak** açılıyor, kedi/balon animasyonu bu ekranda YOK.
2. ~1.4 saniye sonra (`_encourageDelayTimer`) otomatik olarak geçiş başlıyor: hedef içerik (sıradaki triplet ya da final ekranı) state'e hemen yazılıyor (`tripletIndex++` / `stage = final_`), ama `_isTransitioning = true` bayrağıyla ekranda hâlâ "wipe" katmanı gösteriliyor.
3. **Wipe efekti** (`_buildCatWipeTransition`, `_TopWipeClipper`): Ekranın altından üstüne doğru kedi/balon yükselirken (`_transitionController` 0→1, `AnimatedBuilder` + `Positioned` ile), kedinin **geçtiği noktanın altı** zaten yeni ekranı gösteriyor, **üstü** hâlâ eski "Aferin!" ekranı (`ClipRect` ile üstten kırpılıyor). **Fade YOK** — kedi ekranı fiziksel olarak yukarı doğru "açığa çıkarıyor". Kedinin kendi iç animasyonu (el/kuyruk sallama, meow) da aynı `_transitionController`'a bağlı, yani yükseliş ile kedinin kendi hareketi senkron oynuyor.
4. Animasyon bitince (`AnimationStatus.completed`) `_isTransitioning = false` oluyor, geçiş katmanı kalkıyor, hedef ekran (zaten state'te olan) normal şekilde görünüyor.
5. **Çocuğun ekranda hiçbir yere dokunması gerekmiyor** — "Devam Et" butonu tamamen kaldırıldı.

- `_BolumPlayPageState` artık `TickerProviderStateMixin` kullanıyor (AnimationController için vsync).
- Son tripletteyse (final ekrana geçiş), bekleyen API yüklemeleri (`Future.wait(pendingUploads)`) geçişle **paralel** arka planda bekleniyor, `_saveBolumResult()` de aynı şekilde arka planda tamamlanıyor — geçiş animasyonunu bloklamıyor. Final ekranı zaten kendi "sonuçlar hazırlanıyor" bekleme durumunu (`stillWaiting`) gösteriyor.
- Final sonuç ekranındaki "Bölümlere Dön" butonu **değişmedi** — bu ekranda tıklama hâlâ gerekli (bölüm menüsüne dönüş, otomatikleştirilmedi).
- (2026-08-07) Kedi boyutu 220→340px büyütüldü (`catSize`), Civan'ın isteğiyle.

## 7. Pubspec Bağımlılıkları (Mevcut)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.3.0
  flutter_tts: ^4.0.2
  audioplayers: ^6.0.0
  confetti: ^0.8.0
  record: ^7.1.1
  path_provider: ^2.1.2
  http: ^1.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

(`mobx`, `mobx_codegen`, `build_runner`, `speech_to_text` artık kullanılmıyor — eski `phonem_analiz` örnek projesinden kalma, bu projede gerek yok.)

## 11. Rakip Uygulama Araştırması + Motivasyon Sistemi (2026-08-08)

Speech Blubs / Duolingo Kids / DinoLingo / Diltigo incelendi, 6 öneriden ilk 3'ü uygulandı:
- **Gün serisi (streak)**: `StreakService`, bölüm menüsü her açıldığında güncelleniyor, ekranda "🔥 X gün üst üste" bandı.
- **Rozetler**: `RozetlerPage` — İlk Adım, Yıldız Ustası, 3/7 Günlük Seri, Hayvan Koleksiyoncusu, Bölüm Şampiyonu. Çoğu mevcut veriden anlık hesaplanıyor, sadece hayvan koleksiyonu kalıcı kayıt (`AnimalCollectionService`).
- **Ödül çeşitliliği**: köşe hayvanları artık kalıcı olarak "görüldü" kaydediliyor (`animals_collected`), koleksiyon tamamlanınca rozet açılıyor.
- **Veli/Terapist Paneli** (2026-08-08, tamamlandı): `WordHistoryService` her bölüm bitişinde denenen her kelimenin sonucunu (`isPathological`, tarih) kalıcı olarak kaydediyor (`kelime_gecmisi` prefs anahtarı, JSON liste). `VeliPanelPage` bunu kelime bazında özetleyip başarı oranına göre sıralıyor (en çok zorlanılan kelime en üstte) — Bölümler ekranındaki 📊 (insights) ikonundan açılıyor. Bu ekran gelecekteki "Alıştırmalar" modülü için de temel oluşturuyor (hangi kelimeler tekrar edilmeli, buradan belli oluyor).
- Kalan öneri (büyük kapsamlı terapi modülü — ödev atama vb.) henüz ele alınmadı, ayrı epik.

## 12. Görsel Cila (2026-08-08)

Sırayla 4 madde uygulandı:
1. **Font**: `google_fonts` paketi. **Önce Fredoka denendi, Türkçe "ş" harfini bozuk render ettiği emülatör testinde görüldü** ("Başla!" → "Basļa!" çıkıyordu) — `GoogleFonts.baloo2TextTheme()` ile değiştirildi, tüm Türkçe karakterler (ş, ğ, ı, ö, ü, ç) doğru render oluyor. Yeni bir Google Font denenirse mutlaka Türkçe karakterlerle emülatörde test edilmeli, bazı fontların glif desteği eksik olabiliyor.
2. **Gradient/gölge**: `GradientButton` ortak widget'ı (turuncu→pembe gradient + renkli yumuşak gölge) — "Başla!" ve "Bölümlere Dön" butonlarına uygulandı.
3. **App ikonu + splash screen**: `assets/icon/icon.png` (gradient arka plan + beyaz yıldız, Python/Pillow ile üretildi, dış kaynak indirilmedi) + `icon_foreground.png` (adaptive icon/splash için şeffaf). `flutter_launcher_icons` ve `flutter_native_splash` paketleriyle Android/iOS ikonları ve açılış ekranı üretildi (`dart run flutter_launcher_icons` / `dart run flutter_native_splash:create`).
4. **Mikro-etkileşimler**: `GradientButton` basılınca hafifçe küçülüyor (`AnimatedScale`); bölüm listesindeki yıldızlar artık `PopStar` ile sırayla "pop" efektiyle beliriyor (`Curves.elasticOut`).
- Ayrıca: tüm `Navigator.push` çağrıları `SlideFadeRoute` (kayma+solma, 320ms) kullanıyor artık — menü gezinmeleri de artık "tık tık" değil, akıcı geçişli. Kedi/balon wipe efekti sadece 3'lü tamamlama kutlamasında özel an olarak kaldı.

## 13. Emülatör Testi (2026-08-08)

Uygulama emülatörden tamamen silinip (`adb uninstall`), sıfırdan derlenip (`flutter build apk --debug`) kuruldu ve gözle test edildi — sadece hot-reload değil, temiz kurulum. Font hatası (Bölüm 12, madde 1) bu testte bulundu ve düzeltildi. Diğer her şey (maskot, streak bandı, rozet/veli paneli ikonları, büyütülmüş köşe hayvanı, gradient buton) doğru çalışıyor. Kelime kartlarındaki (`kedi`, `top` vb.) yazı fontu Flutter'dan gelmiyor — `assets/3-4/*.png` gibi kelime görsellerinin içine baştan beri gömülü, bizim font/tema değişikliklerinden etkilenmiyor.