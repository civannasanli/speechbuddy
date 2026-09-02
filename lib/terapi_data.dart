// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.
// Kaynak: drivelinkiiçindekiler/*.pdf,  üretici: tool/extract_dilart.py + tool/gen_dart.py
//
// Her TerapiEkran bir PDF sayfasına karşılık gelir; sayfadaki öğe sayısı
// doğrudan ekranda gösterilecek kart sayısıdır (hece 4, kelime 3, grup 2, cümle 1).

enum TerapiAsama { heceler, kelimeler, kelimeGruplari, cumleler }

class TerapiOge {
  final String metin;
  /// Hecelerde görsel yok — kart büyük metin olarak çizilir.
  final String? gorsel;
  const TerapiOge(this.metin, this.gorsel);
}

class TerapiEkran {
  final TerapiAsama asama;
  /// BAŞTA / ORTADA / SONDA — yalnız kelimeler aşamasında dolu.
  /// Bölüm sonu sonuç ekranı bu değer değiştiğinde çıkar.
  final String? konum;
  final List<TerapiOge> ogeler;
  const TerapiEkran(this.asama, this.konum, this.ogeler);
}

class TerapiSes {
  final String harf;
  final String yonerge;
  final String yonergeGorsel;
  final List<TerapiEkran> ekranlar;
  const TerapiSes(this.harf, this.yonerge, this.yonergeGorsel, this.ekranlar);
}

const List<TerapiSes> kTerapiSesleri = [
  TerapiSes('B', 'Dudaklarını birbirine bastır, ağzını havayla doldur ve dudaklarını açarak \'bum\' diye patlat.', 'assets/terapi/b/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ba', null),
      TerapiOge('bı', null),
      TerapiOge('bo', null),
      TerapiOge('bu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('be', null),
      TerapiOge('bi', null),
      TerapiOge('bö', null),
      TerapiOge('bü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aba', null),
      TerapiOge('ıbı', null),
      TerapiOge('obo', null),
      TerapiOge('ubu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ebe', null),
      TerapiOge('ibi', null),
      TerapiOge('öbö', null),
      TerapiOge('übü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('bal', 'assets/terapi/b/bal.webp'),
      TerapiOge('buz', 'assets/terapi/b/buz.webp'),
      TerapiOge('bot', 'assets/terapi/b/bot.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('balık', 'assets/terapi/b/balik.webp'),
      TerapiOge('burun', 'assets/terapi/b/burun.webp'),
      TerapiOge('bayrak', 'assets/terapi/b/bayrak.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('biberon', 'assets/terapi/b/biberon.webp'),
      TerapiOge('bezelye', 'assets/terapi/b/bezelye.webp'),
      TerapiOge('bisiklet', 'assets/terapi/b/bisiklet.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('sabun', 'assets/terapi/b/sabun.webp'),
      TerapiOge('tabak', 'assets/terapi/b/tabak.webp'),
      TerapiOge('robot', 'assets/terapi/b/robot.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('araba', 'assets/terapi/b/araba.webp'),
      TerapiOge('elbise', 'assets/terapi/b/elbise.webp'),
      TerapiOge('kelebek', 'assets/terapi/b/kelebek.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kurbağa', 'assets/terapi/b/kurbaga.webp'),
      TerapiOge('otobüs', 'assets/terapi/b/otobus.webp'),
      TerapiOge('leblebi', 'assets/terapi/b/leblebi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('pembe bisiklet', 'assets/terapi/b/pembe_bisiklet.webp'),
      TerapiOge('ballı kurabiye', 'assets/terapi/b/balli_kurabiye.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('benekli balık', 'assets/terapi/b/benekli_balik.webp'),
      TerapiOge('balerin babeti', 'assets/terapi/b/balerin_babeti.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('bozuk araba', 'assets/terapi/b/bozuk_araba.webp'),
      TerapiOge('büyük balina', 'assets/terapi/b/buyuk_balina.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Buse balıkları besliyor.', 'assets/terapi/b/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Berke basketbol oynuyor.', 'assets/terapi/b/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kurbağa bataklıkta zıplıyor.', 'assets/terapi/b/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kübra pembe elbiseyi beğendi.', 'assets/terapi/b/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ebru kumbarada para biriktiriyor.', 'assets/terapi/b/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Berfin boncuktan bileklik yapıyor.', 'assets/terapi/b/cumle6.webp'),
    ]),
  ]),
  TerapiSes('P', 'Dudaklarını birbirine bastır, ağzını havayla doldur ve dudaklarını açarak \'puf\' diye patlat.', 'assets/terapi/p/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('pa', null),
      TerapiOge('pı', null),
      TerapiOge('po', null),
      TerapiOge('pu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('pe', null),
      TerapiOge('pi', null),
      TerapiOge('pö', null),
      TerapiOge('pü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('apa', null),
      TerapiOge('ıpı', null),
      TerapiOge('opo', null),
      TerapiOge('upu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('epe', null),
      TerapiOge('ipi', null),
      TerapiOge('öpö', null),
      TerapiOge('üpü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('pil', 'assets/terapi/p/pil.webp'),
      TerapiOge('park', 'assets/terapi/p/park.webp'),
      TerapiOge('pis', 'assets/terapi/p/pis.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('pizza', 'assets/terapi/p/pizza.webp'),
      TerapiOge('pasta', 'assets/terapi/p/pasta.webp'),
      TerapiOge('panda', 'assets/terapi/p/panda.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('portakal', 'assets/terapi/p/portakal.webp'),
      TerapiOge('piyano', 'assets/terapi/p/piyano.webp'),
      TerapiOge('palyaço', 'assets/terapi/p/palyaco.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('sepet', 'assets/terapi/p/sepet.webp'),
      TerapiOge('yaprak', 'assets/terapi/p/yaprak.webp'),
      TerapiOge('şapka', 'assets/terapi/p/sapka.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('köpek', 'assets/terapi/p/kopek.webp'),
      TerapiOge('pipet', 'assets/terapi/p/pipet.webp'),
      TerapiOge('kapı', 'assets/terapi/p/kapi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('ahtapot', 'assets/terapi/p/ahtapot.webp'),
      TerapiOge('süpürge', 'assets/terapi/p/supurge.webp'),
      TerapiOge('papağan', 'assets/terapi/p/papagan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('kalp', 'assets/terapi/p/kalp.webp'),
      TerapiOge('top', 'assets/terapi/p/top.webp'),
      TerapiOge('çöp', 'assets/terapi/p/cop.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('sincap', 'assets/terapi/p/sincap.webp'),
      TerapiOge('kitap', 'assets/terapi/p/kitap.webp'),
      TerapiOge('çorap', 'assets/terapi/p/corap.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('teleskop', 'assets/terapi/p/teleskop.webp'),
      TerapiOge('lolipop', 'assets/terapi/p/lolipop.webp'),
      TerapiOge('mikroskop', 'assets/terapi/p/mikroskop.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('piknik sepeti', 'assets/terapi/p/piknik_sepeti.webp'),
      TerapiOge('portakallı pasta', 'assets/terapi/p/portakalli_pasta.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('çöp poşeti', 'assets/terapi/p/cop_poseti.webp'),
      TerapiOge('polis köpeği', 'assets/terapi/p/polis_kopegi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('şapkalı penguen', 'assets/terapi/p/sapkali_penguen.webp'),
      TerapiOge('Pamuk Prenses', 'assets/terapi/p/pamuk_prenses.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Polat piknik yapıyor.', 'assets/terapi/p/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Poyraz pizza pişiriyor.', 'assets/terapi/p/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Palyaçonun topu patladı.', 'assets/terapi/p/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('İpek portakallı pasta yapıyor.', 'assets/terapi/p/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Alp papatyanın yapraklarını koparıyor.', 'assets/terapi/p/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çöpçü pis çöpleri topluyor.', 'assets/terapi/p/cumle6.webp'),
    ]),
  ]),
  TerapiSes('M', 'Dudaklarını birbirine nazikçe yapıştır ve sakın açma. Çok sevdiğin bir dondurmayı görmüşsün gibi burnundan uzun bir \'Mmmm\' sesi çıkar.', 'assets/terapi/m/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ma', null),
      TerapiOge('mı', null),
      TerapiOge('mo', null),
      TerapiOge('mu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('me', null),
      TerapiOge('mi', null),
      TerapiOge('mö', null),
      TerapiOge('mü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ama', null),
      TerapiOge('ımı', null),
      TerapiOge('omo', null),
      TerapiOge('umu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eme', null),
      TerapiOge('imi', null),
      TerapiOge('ömö', null),
      TerapiOge('ümü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('muz', 'assets/terapi/m/muz.webp'),
      TerapiOge('mum', 'assets/terapi/m/mum.webp'),
      TerapiOge('mont', 'assets/terapi/m/mont.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('masa', 'assets/terapi/m/masa.webp'),
      TerapiOge('maymun', 'assets/terapi/m/maymun.webp'),
      TerapiOge('mısır', 'assets/terapi/m/misir.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('merdiven', 'assets/terapi/m/merdiven.webp'),
      TerapiOge('makarna', 'assets/terapi/m/makarna.webp'),
      TerapiOge('mandalina', 'assets/terapi/m/mandalina.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kamyon', 'assets/terapi/m/kamyon.webp'),
      TerapiOge('simit', 'assets/terapi/m/simit.webp'),
      TerapiOge('gemi', 'assets/terapi/m/gemi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('timsah', 'assets/terapi/m/timsah.webp'),
      TerapiOge('armut', 'assets/terapi/m/armut.webp'),
      TerapiOge('yağmur', 'assets/terapi/m/yagmur.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('uçurtma', 'assets/terapi/m/ucurtma.webp'),
      TerapiOge('dondurma', 'assets/terapi/m/dondurma.webp'),
      TerapiOge('pijama', 'assets/terapi/m/pijama.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('çam', 'assets/terapi/m/cam.webp'),
      TerapiOge('kum', 'assets/terapi/m/kum.webp'),
      TerapiOge('çim', 'assets/terapi/m/cim.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('üzüm', 'assets/terapi/m/uzum.webp'),
      TerapiOge('resim', 'assets/terapi/m/resim.webp'),
      TerapiOge('takvim', 'assets/terapi/m/takvim.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('kalem', 'assets/terapi/m/kalem.webp'),
      TerapiOge('ressam', 'assets/terapi/m/ressam.webp'),
      TerapiOge('akvaryum', 'assets/terapi/m/akvaryum.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('sevimli örümcek', 'assets/terapi/m/sevimli_orumcek.webp'),
      TerapiOge('kırmızı elma', 'assets/terapi/m/kirmizi_elma.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('maymunun muzu', 'assets/terapi/m/maymunun_muzu.webp'),
      TerapiOge('limonlu dondurma', 'assets/terapi/m/limonlu_dondurma.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('patlamış mısır', 'assets/terapi/m/patlamis_misir.webp'),
      TerapiOge('pijama takımı', 'assets/terapi/m/pijama_takimi.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çamaşırlar makinede yıkanıyor.', 'assets/terapi/m/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Domatesleri kamyona yüklüyorum.', 'assets/terapi/m/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Marketten ekmek alıyorum.', 'assets/terapi/m/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Meyveleri mutfaktaki masaya koydum.', 'assets/terapi/m/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Mete mavi gemiden iniyor.', 'assets/terapi/m/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Manavdan kırmızı elma alıyorum.', 'assets/terapi/m/cumle6.webp'),
    ]),
  ]),
  TerapiSes('N', 'Dudaklarını \'ce-eee\' yapar gibi aç ve gülümse. Dilinin ucunu üst dişlerinin hemen arkasındaki tümseğe yapıştır. Dilini oradan hiç ayırmadan burnundan \'Nnnnn\' diye ses çıkar.', 'assets/terapi/n/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('na', null),
      TerapiOge('nı', null),
      TerapiOge('no', null),
      TerapiOge('nu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ne', null),
      TerapiOge('ni', null),
      TerapiOge('nö', null),
      TerapiOge('nü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ana', null),
      TerapiOge('ını', null),
      TerapiOge('ono', null),
      TerapiOge('unu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ene', null),
      TerapiOge('ini', null),
      TerapiOge('önö', null),
      TerapiOge('ünü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('nar', 'assets/terapi/n/nar.webp'),
      TerapiOge('nal', 'assets/terapi/n/nal.webp'),
      TerapiOge('ney', 'assets/terapi/n/ney.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('nine', 'assets/terapi/n/nine.webp'),
      TerapiOge('nehir', 'assets/terapi/n/nehir.webp'),
      TerapiOge('nane', 'assets/terapi/n/nane.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('nilüfer', 'assets/terapi/n/nilufer.webp'),
      TerapiOge('narenciye', 'assets/terapi/n/narenciye.webp'),
      TerapiOge('nektarin', 'assets/terapi/n/nektarin.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('anne', 'assets/terapi/n/anne.webp'),
      TerapiOge('güneş', 'assets/terapi/n/gunes.webp'),
      TerapiOge('çanta', 'assets/terapi/n/canta.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('inek', 'assets/terapi/n/inek.webp'),
      TerapiOge('mantar', 'assets/terapi/n/mantar.webp'),
      TerapiOge('fındık', 'assets/terapi/n/findik.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('oyuncak', 'assets/terapi/n/oyuncak.webp'),
      TerapiOge('dinozor', 'assets/terapi/n/dinozor.webp'),
      TerapiOge('satranç', 'assets/terapi/n/satranc.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('balon', 'assets/terapi/n/balon.webp'),
      TerapiOge('koyun', 'assets/terapi/n/koyun.webp'),
      TerapiOge('tren', 'assets/terapi/n/tren.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('tavşan', 'assets/terapi/n/tavsan.webp'),
      TerapiOge('keman', 'assets/terapi/n/keman.webp'),
      TerapiOge('kaptan', 'assets/terapi/n/kaptan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('pantolon', 'assets/terapi/n/pantolon.webp'),
      TerapiOge('penguen', 'assets/terapi/n/penguen.webp'),
      TerapiOge('mikrofon', 'assets/terapi/n/mikrofon.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('penguenin pateni', 'assets/terapi/n/penguenin_pateni.webp'),
      TerapiOge('turuncu kamyon', 'assets/terapi/n/turuncu_kamyon.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('neşeli tavşan', 'assets/terapi/n/neseli_tavsan.webp'),
      TerapiOge('sincabın mantarı', 'assets/terapi/n/sincabin_mantari.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('ninenin bastonu', 'assets/terapi/n/ninenin_bastonu.webp'),
      TerapiOge('vişneli dondurma', 'assets/terapi/n/visneli_dondurma.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Annemle limonata yapıyorum.', 'assets/terapi/n/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Nermin trene biniyor.', 'assets/terapi/n/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ambulans hastaneye geldi.', 'assets/terapi/n/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Can manavdan nar alıyor.', 'assets/terapi/n/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Hakan koyunlarını çimenlerde otlatıyor.', 'assets/terapi/n/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Öğretmen öğrencileriyle piyano çalıyor.', 'assets/terapi/n/cumle6.webp'),
    ]),
  ]),
  TerapiSes('D', 'Dilinin ucunu, üst dişlerinin arkasındaki o küçük tümseğe yapıştır. Ses motorunu çalıştır (boğazın titresin) ve dilini aşağı doğru hızla iterek \'Dddd\' diye ses çıkar.', 'assets/terapi/d/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('da', null),
      TerapiOge('dı', null),
      TerapiOge('do', null),
      TerapiOge('du', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('de', null),
      TerapiOge('di', null),
      TerapiOge('dö', null),
      TerapiOge('dü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ada', null),
      TerapiOge('ıdı', null),
      TerapiOge('odo', null),
      TerapiOge('udu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ede', null),
      TerapiOge('idi', null),
      TerapiOge('ödö', null),
      TerapiOge('üdü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('dil', 'assets/terapi/d/dil.webp'),
      TerapiOge('diş', 'assets/terapi/d/dis.webp'),
      TerapiOge('dans', 'assets/terapi/d/dans.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('deve', 'assets/terapi/d/deve.webp'),
      TerapiOge('davul', 'assets/terapi/d/davul.webp'),
      TerapiOge('doktor', 'assets/terapi/d/doktor.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('dondurma', 'assets/terapi/d/dondurma.webp'),
      TerapiOge('dedektif', 'assets/terapi/d/dedektif.webp'),
      TerapiOge('domates', 'assets/terapi/d/domates.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('ördek', 'assets/terapi/d/ordek.webp'),
      TerapiOge('düdük', 'assets/terapi/d/duduk.webp'),
      TerapiOge('kedi', 'assets/terapi/d/kedi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('eldiven', 'assets/terapi/d/eldiven.webp'),
      TerapiOge('sandalye', 'assets/terapi/d/sandalye.webp'),
      TerapiOge('kaydırak', 'assets/terapi/d/kaydirak.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('hediye', 'assets/terapi/d/hediye.webp'),
      TerapiOge('arkadaş', 'assets/terapi/d/arkadas.webp'),
      TerapiOge('çaydanlık', 'assets/terapi/d/caydanlik.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('kardan adam', 'assets/terapi/d/kardan_adam.webp'),
      TerapiOge('deniz yıldızı', 'assets/terapi/d/deniz_yildizi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('dondurma dükkanı', 'assets/terapi/d/dondurma_dukkani.webp'),
      TerapiOge('dedenin sandalyesi', 'assets/terapi/d/dedenin_sandalyesi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('dönme dolap', 'assets/terapi/d/donme_dolap.webp'),
      TerapiOge('diş doktoru', 'assets/terapi/d/dis_doktoru.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kedi minderde uyudu.', 'assets/terapi/d/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Dişçi dişini dolduruyor.', 'assets/terapi/d/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Dede radyo dinliyor.', 'assets/terapi/d/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Dalgıç derin denize daldı.', 'assets/terapi/d/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Davulcu düğünde davul çaldı.', 'assets/terapi/d/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Doğa arkadaşıyla deveye bindi.', 'assets/terapi/d/cumle6.webp'),
    ]),
  ]),
  TerapiSes('T', 'Dilinin ucunu üst dişlerinin arkasındaki küçük tepeye dokundur ve orada bekle. Şimdi ağzının içinde biriktirdiğin rüzgarı, dilini aniden aşağı çekerek \'Ttt\' diye dışarı fırlat.', 'assets/terapi/t/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ta', null),
      TerapiOge('tı', null),
      TerapiOge('to', null),
      TerapiOge('tu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('te', null),
      TerapiOge('ti', null),
      TerapiOge('tö', null),
      TerapiOge('tü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ata', null),
      TerapiOge('ıtı', null),
      TerapiOge('oto', null),
      TerapiOge('utu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ete', null),
      TerapiOge('iti', null),
      TerapiOge('ötö', null),
      TerapiOge('ütü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('taç', 'assets/terapi/t/tac.webp'),
      TerapiOge('tır', 'assets/terapi/t/tir.webp'),
      TerapiOge('top', 'assets/terapi/t/top.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('tavşan', 'assets/terapi/t/tavsan.webp'),
      TerapiOge('tenis', 'assets/terapi/t/tenis.webp'),
      TerapiOge('timsah', 'assets/terapi/t/timsah.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('tencere', 'assets/terapi/t/tencere.webp'),
      TerapiOge('telefon', 'assets/terapi/t/telefon.webp'),
      TerapiOge('televizyon', 'assets/terapi/t/televizyon.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('pasta', 'assets/terapi/t/pasta.webp'),
      TerapiOge('paten', 'assets/terapi/t/paten.webp'),
      TerapiOge('çanta', 'assets/terapi/t/canta.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('patates', 'assets/terapi/t/patates.webp'),
      TerapiOge('anahtar', 'assets/terapi/t/anahtar.webp'),
      TerapiOge('uçurtma', 'assets/terapi/t/ucurtma.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('süt', 'assets/terapi/t/sut.webp'),
      TerapiOge('şort', 'assets/terapi/t/sort.webp'),
      TerapiOge('tost', 'assets/terapi/t/tost.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('armut', 'assets/terapi/t/armut.webp'),
      TerapiOge('pilot', 'assets/terapi/t/pilot.webp'),
      TerapiOge('robot', 'assets/terapi/t/robot.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('paraşüt', 'assets/terapi/t/parasut.webp'),
      TerapiOge('ahtapot', 'assets/terapi/t/ahtapot.webp'),
      TerapiOge('labirent', 'assets/terapi/t/labirent.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('şeftalili yoğurt', 'assets/terapi/t/seftalili_yogurt.webp'),
      TerapiOge('basketbol topu', 'assets/terapi/t/basketbol_topu.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('lacivert tişört', 'assets/terapi/t/lacivert_tisort.webp'),
      TerapiOge('patates kızartması', 'assets/terapi/t/patates_kizartmasi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('çikolatalı pasta', 'assets/terapi/t/cikolatali_pasta.webp'),
      TerapiOge('tavada yumurta', 'assets/terapi/t/tavada_yumurta.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Futbol topu patladı.', 'assets/terapi/t/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Atın tüylerini tarıyor.', 'assets/terapi/t/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Terzi pantolonu ütülüyor.', 'assets/terapi/t/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Köfteyle patatesi tavada kızartıyor.', 'assets/terapi/t/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Tarlaya turp tohumu ekti.', 'assets/terapi/t/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Toprak bisikletini tamir etti.', 'assets/terapi/t/cumle6.webp'),
    ]),
  ]),
  TerapiSes('K', 'Ağzını kocaman aç. Dilini alt dişlerinin arkasına sakla. Şimdi boğazının arkasından sanki gıcık tutmuş gibi \'Kuh\' diye öksür.', 'assets/terapi/k/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ka', null),
      TerapiOge('kı', null),
      TerapiOge('ko', null),
      TerapiOge('ku', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ke', null),
      TerapiOge('ki', null),
      TerapiOge('kö', null),
      TerapiOge('kü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aka', null),
      TerapiOge('ıkı', null),
      TerapiOge('oko', null),
      TerapiOge('uku', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eke', null),
      TerapiOge('iki', null),
      TerapiOge('ökö', null),
      TerapiOge('ükü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('kaz', 'assets/terapi/k/kaz.webp'),
      TerapiOge('kel', 'assets/terapi/k/kel.webp'),
      TerapiOge('kuş', 'assets/terapi/k/kus.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('kalem', 'assets/terapi/k/kalem.webp'),
      TerapiOge('küpe', 'assets/terapi/k/kupe.webp'),
      TerapiOge('kiraz', 'assets/terapi/k/kiraz.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('kanguru', 'assets/terapi/k/kanguru.webp'),
      TerapiOge('kurbağa', 'assets/terapi/k/kurbaga.webp'),
      TerapiOge('karınca', 'assets/terapi/k/karinca.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('asker', 'assets/terapi/k/asker.webp'),
      TerapiOge('baykuş', 'assets/terapi/k/baykus.webp'),
      TerapiOge('makas', 'assets/terapi/k/makas.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('ekmek', 'assets/terapi/k/ekmek.webp'),
      TerapiOge('şeker', 'assets/terapi/k/seker.webp'),
      TerapiOge('okul', 'assets/terapi/k/okul.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('çekirge', 'assets/terapi/k/cekirge.webp'),
      TerapiOge('pinokyo', 'assets/terapi/k/pinokyo.webp'),
      TerapiOge('korkuluk', 'assets/terapi/k/korkuluk.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('park', 'assets/terapi/k/park.webp'),
      TerapiOge('fok', 'assets/terapi/k/fok.webp'),
      TerapiOge('kek', 'assets/terapi/k/kek.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('gözlük', 'assets/terapi/k/gozluk.webp'),
      TerapiOge('çilek', 'assets/terapi/k/cilek.webp'),
      TerapiOge('köpek', 'assets/terapi/k/kopek.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('kelebek', 'assets/terapi/k/kelebek.webp'),
      TerapiOge('oyuncak', 'assets/terapi/k/oyuncak.webp'),
      TerapiOge('salıncak', 'assets/terapi/k/salincak.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('tavuk kümesi', 'assets/terapi/k/tavuk_kumesi.webp'),
      TerapiOge('kangurunun kesesi', 'assets/terapi/k/kangurunun_kesesi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('bulaşık makinesi', 'assets/terapi/k/bulasik_makinesi.webp'),
      TerapiOge('topuklu ayakkabı', 'assets/terapi/k/topuklu_ayakkabi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('çalışkan karınca', 'assets/terapi/k/caliskan_karinca.webp'),
      TerapiOge('benekli inek', 'assets/terapi/k/benekli_inek.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çocuk kızakla kayıyor.', 'assets/terapi/k/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ekmekleri makinede kızartıyor.', 'assets/terapi/k/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Hikaye kitabı okuyor.', 'assets/terapi/k/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Berk piknikte karpuz kesiyor.', 'assets/terapi/k/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kayra kırmızı kazağını katlıyor.', 'assets/terapi/k/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kağan kaplumbağasıyla kaydıraktan kayıyor.', 'assets/terapi/k/cumle6.webp'),
    ]),
  ]),
  TerapiSes('G', 'Başını hafifçe arkaya yasla. Sanki ağzında su varmış da gargara yapıyormuşsun gibi, boğazını titreterek ses çıkar.', 'assets/terapi/g/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ga', null),
      TerapiOge('gı', null),
      TerapiOge('go', null),
      TerapiOge('gu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ge', null),
      TerapiOge('gi', null),
      TerapiOge('gö', null),
      TerapiOge('gü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aga', null),
      TerapiOge('ıgı', null),
      TerapiOge('ogo', null),
      TerapiOge('ugu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ege', null),
      TerapiOge('igi', null),
      TerapiOge('ögö', null),
      TerapiOge('ügü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('gül', 'assets/terapi/g/gul.webp'),
      TerapiOge('göz', 'assets/terapi/g/goz.webp'),
      TerapiOge('göl', 'assets/terapi/g/gol.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('geyik', 'assets/terapi/g/geyik.webp'),
      TerapiOge('gömlek', 'assets/terapi/g/gomlek.webp'),
      TerapiOge('garson', 'assets/terapi/g/garson.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('gökkuşağı', 'assets/terapi/g/gokkusagi.webp'),
      TerapiOge('gazete', 'assets/terapi/g/gazete.webp'),
      TerapiOge('gelinlik', 'assets/terapi/g/gelinlik.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('yorgan', 'assets/terapi/g/yorgan.webp'),
      TerapiOge('silgi', 'assets/terapi/g/silgi.webp'),
      TerapiOge('dergi', 'assets/terapi/g/dergi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('yengeç', 'assets/terapi/g/yengec.webp'),
      TerapiOge('gölge', 'assets/terapi/g/golge.webp'),
      TerapiOge('mangal', 'assets/terapi/g/mangal.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('salyangoz', 'assets/terapi/g/salyangoz.webp'),
      TerapiOge('bilgisayar', 'assets/terapi/g/bilgisayar.webp'),
      TerapiOge('gergedan', 'assets/terapi/g/gergedan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('org', 'assets/terapi/g/org.webp'),
      TerapiOge('bovling', 'assets/terapi/g/bovling.webp'),
      TerapiOge('şezlong', 'assets/terapi/g/sezlong.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('çekirge', 'assets/terapi/g/cekirge.webp'),
      TerapiOge('süpürge', 'assets/terapi/g/supurge.webp'),
      TerapiOge('flamingo', 'assets/terapi/g/flamingo.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('garaj girişi', 'assets/terapi/g/garaj_girisi.webp'),
      TerapiOge('göbekli goril', 'assets/terapi/g/gobekli_goril.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('rengarenk gökkuşağı', 'assets/terapi/g/rengarenk_gokkusagi.webp'),
      TerapiOge('rüzgar gülü', 'assets/terapi/g/ruzgar_gulu.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('karganın gagası', 'assets/terapi/g/karganin_gagasi.webp'),
      TerapiOge('gazlı gazoz', 'assets/terapi/g/gazli_gazoz.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Garson gazoz getirdi.', 'assets/terapi/g/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Dalgıç göle giriyor.', 'assets/terapi/g/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Gaye sergiyi geziyor.', 'assets/terapi/g/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Görevli kanguruları gezginlere gösteriyor.', 'assets/terapi/g/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Gizem çizgili şezlongda güneşleniyor.', 'assets/terapi/g/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Güney gezegenleri, galaksileri gözlemliyor.', 'assets/terapi/g/cumle6.webp'),
    ]),
  ]),
  TerapiSes('F', 'Üst dişlerini alt dudağının üzerine nazikçe koy (Tıpkı bir tavşan gibi). Şimdi dişlerinin arasından dışarıya rüzgar üfle: Ffff!', 'assets/terapi/f/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('fa', null),
      TerapiOge('fı', null),
      TerapiOge('fo', null),
      TerapiOge('fu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('fe', null),
      TerapiOge('fi', null),
      TerapiOge('fö', null),
      TerapiOge('fü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('afa', null),
      TerapiOge('ıfı', null),
      TerapiOge('ofo', null),
      TerapiOge('ufu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('efe', null),
      TerapiOge('ifi', null),
      TerapiOge('öfö', null),
      TerapiOge('üfü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('fil', 'assets/terapi/f/fil.webp'),
      TerapiOge('fiş', 'assets/terapi/f/fis.webp'),
      TerapiOge('fön', 'assets/terapi/f/fon.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('fincan', 'assets/terapi/f/fincan.webp'),
      TerapiOge('fırça', 'assets/terapi/f/firca.webp'),
      TerapiOge('flüt', 'assets/terapi/f/flut.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('fermuar', 'assets/terapi/f/fermuar.webp'),
      TerapiOge('fırtına', 'assets/terapi/f/firtina.webp'),
      TerapiOge('futbolcu', 'assets/terapi/f/futbolcu.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kafes', 'assets/terapi/f/kafes.webp'),
      TerapiOge('şoför', 'assets/terapi/f/sofor.webp'),
      TerapiOge('parfüm', 'assets/terapi/f/parfum.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('telefon', 'assets/terapi/f/telefon.webp'),
      TerapiOge('itfaiye', 'assets/terapi/f/itfaiye.webp'),
      TerapiOge('kuaför', 'assets/terapi/f/kuafor.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('lif', 'assets/terapi/f/lif.webp'),
      TerapiOge('tef', 'assets/terapi/f/tef.webp'),
      TerapiOge('sörf', 'assets/terapi/f/sorf.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('hedef', 'assets/terapi/f/hedef.webp'),
      TerapiOge('çarşaf', 'assets/terapi/f/carsaf.webp'),
      TerapiOge('sınıf', 'assets/terapi/f/sinif.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('dedektif', 'assets/terapi/f/dedektif.webp'),
      TerapiOge('fotoğraf', 'assets/terapi/f/fotograf.webp'),
      TerapiOge('lokomotif', 'assets/terapi/f/lokomotif.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('fırında köfte', 'assets/terapi/f/firinda_kofte.webp'),
      TerapiOge('raftaki fincan', 'assets/terapi/f/raftaki_fincan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('fırfırlı çarşaf', 'assets/terapi/f/firfirli_carsaf.webp'),
      TerapiOge('tarif defteri', 'assets/terapi/f/tarif_defteri.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('parfüm fabrikası', 'assets/terapi/f/parfum_fabrikasi.webp'),
      TerapiOge('telefon kılıfı', 'assets/terapi/f/telefon_kilifi.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Şeftalileri fileye koyuyor.', 'assets/terapi/f/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çiftçi fareyi kovalıyor.', 'assets/terapi/f/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Filiz flüte üfledi.', 'assets/terapi/f/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kuaför Fatma, fön çekiyor.', 'assets/terapi/f/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Fulya fayansları fırçayla fırçaladı.', 'assets/terapi/f/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Fotoğrafçı filin fotoğrafını çekiyor.', 'assets/terapi/f/cumle6.webp'),
    ]),
  ]),
  TerapiSes('V', 'Üst dişlerini alt dudağının üzerine hafifçe bastır. Şimdi ağzını hiç açmadan, dudağını titreterek \'Vvvvv\' diye ses çıkar. Dudağın gıdıklanmalı!', 'assets/terapi/v/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('va', null),
      TerapiOge('vı', null),
      TerapiOge('vo', null),
      TerapiOge('vu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ve', null),
      TerapiOge('vi', null),
      TerapiOge('vö', null),
      TerapiOge('vü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ava', null),
      TerapiOge('ıvı', null),
      TerapiOge('ovo', null),
      TerapiOge('uvu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eve', null),
      TerapiOge('ivi', null),
      TerapiOge('övö', null),
      TerapiOge('üvü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('vinç', 'assets/terapi/v/vinc.webp'),
      TerapiOge('vapur', 'assets/terapi/v/vapur.webp'),
      TerapiOge('vişne', 'assets/terapi/v/visne.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('vazo', 'assets/terapi/v/vazo.webp'),
      TerapiOge('valiz', 'assets/terapi/v/valiz.webp'),
      TerapiOge('vagon', 'assets/terapi/v/vagon.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('voleybol', 'assets/terapi/v/voleybol.webp'),
      TerapiOge('vitamin', 'assets/terapi/v/vitamin.webp'),
      TerapiOge('veteriner', 'assets/terapi/v/veteriner.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kivi', 'assets/terapi/v/kivi.webp'),
      TerapiOge('kavun', 'assets/terapi/v/kavun.webp'),
      TerapiOge('ayva', 'assets/terapi/v/ayva.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('havlu', 'assets/terapi/v/havlu.webp'),
      TerapiOge('küvet', 'assets/terapi/v/kuvet.webp'),
      TerapiOge('tava', 'assets/terapi/v/tava.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('lavabo', 'assets/terapi/v/lavabo.webp'),
      TerapiOge('kravat', 'assets/terapi/v/kravat.webp'),
      TerapiOge('kahvaltı', 'assets/terapi/v/kahvalti.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('ev', 'assets/terapi/v/ev.webp'),
      TerapiOge('dev', 'assets/terapi/v/dev.webp'),
      TerapiOge('alev', 'assets/terapi/v/alev.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('şınav', 'assets/terapi/v/sinav.webp'),
      TerapiOge('pilav', 'assets/terapi/v/pilav.webp'),
      TerapiOge('ödev', 'assets/terapi/v/odev.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('sınav', 'assets/terapi/v/sinav_2.webp'),
      TerapiOge('civciv', 'assets/terapi/v/civciv.webp'),
      TerapiOge('manav', 'assets/terapi/v/manav.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('tavuklu pilav', 'assets/terapi/v/tavuklu_pilav.webp'),
      TerapiOge('kahverengi bavul', 'assets/terapi/v/kahverengi_bavul.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('Hacivat’ın davulu', 'assets/terapi/v/hacivat_in_davulu.webp'),
      TerapiOge('kahvaltı vakti', 'assets/terapi/v/kahvalti_vakti.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('yavru güvercin', 'assets/terapi/v/yavru_guvercin.webp'),
      TerapiOge('ceviz çuvalı', 'assets/terapi/v/ceviz_cuvali.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Tavuk civcivleri seviyor.', 'assets/terapi/v/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Veli merdiven çıkıyor.', 'assets/terapi/v/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Tavşana havuç veriyor.', 'assets/terapi/v/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Davulcu Davut davula vuruyor.', 'assets/terapi/v/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Deve mavi kovayı devirdi.', 'assets/terapi/v/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Veteriner sevimli hayvanlara bakıyor.', 'assets/terapi/v/cumle6.webp'),
    ]),
  ]),
  TerapiSes('S', 'Kocaman gülümse. Dişlerini yavaşça birbirine değdir ve kapat. Dilini dişlerinin arkasına sakla. Şimdi dişlerinin arasından yavaşça üfle: Sssss!', 'assets/terapi/s/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('sa', null),
      TerapiOge('sı', null),
      TerapiOge('so', null),
      TerapiOge('su', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('se', null),
      TerapiOge('si', null),
      TerapiOge('sö', null),
      TerapiOge('sü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('asa', null),
      TerapiOge('ısı', null),
      TerapiOge('oso', null),
      TerapiOge('usu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ese', null),
      TerapiOge('isi', null),
      TerapiOge('ösö', null),
      TerapiOge('üsü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('su', 'assets/terapi/s/su.webp'),
      TerapiOge('süt', 'assets/terapi/s/sut.webp'),
      TerapiOge('saç', 'assets/terapi/s/sac.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('saat', 'assets/terapi/s/saat.webp'),
      TerapiOge('sinek', 'assets/terapi/s/sinek.webp'),
      TerapiOge('serçe', 'assets/terapi/s/serce.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('sarımsak', 'assets/terapi/s/sarimsak.webp'),
      TerapiOge('sürahi', 'assets/terapi/s/surahi.webp'),
      TerapiOge('solucan', 'assets/terapi/s/solucan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('tost', 'assets/terapi/s/tost.webp'),
      TerapiOge('kask', 'assets/terapi/s/kask.webp'),
      TerapiOge('test', 'assets/terapi/s/test.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('yastık', 'assets/terapi/s/yastik.webp'),
      TerapiOge('aslan', 'assets/terapi/s/aslan.webp'),
      TerapiOge('hostes', 'assets/terapi/s/hostes.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('pusula', 'assets/terapi/s/pusula.webp'),
      TerapiOge('postacı', 'assets/terapi/s/postaci.webp'),
      TerapiOge('yarasa', 'assets/terapi/s/yarasa.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('makas', 'assets/terapi/s/makas.webp'),
      TerapiOge('yunus', 'assets/terapi/s/yunus.webp'),
      TerapiOge('tenis', 'assets/terapi/s/tenis.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('ananas', 'assets/terapi/s/ananas.webp'),
      TerapiOge('domates', 'assets/terapi/s/domates.webp'),
      TerapiOge('prenses', 'assets/terapi/s/prenses.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('ambulans', 'assets/terapi/s/ambulans.webp'),
      TerapiOge('minibüs', 'assets/terapi/s/minibus.webp'),
      TerapiOge('otobüs', 'assets/terapi/s/otobus.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('sebze kasası', 'assets/terapi/s/sebze_kasasi.webp'),
      TerapiOge('su savaşı', 'assets/terapi/s/su_savasi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('polis arabası', 'assets/terapi/s/polis_arabasi.webp'),
      TerapiOge('korsan gemisi', 'assets/terapi/s/korsan_gemisi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('kestaneli pasta', 'assets/terapi/s/kestaneli_pasta.webp'),
      TerapiOge('susamlı simit', 'assets/terapi/s/susamli_simit.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Serkan testereyle kesiyor.', 'assets/terapi/s/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Senanur salıncakta sallanıyor.', 'assets/terapi/s/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Saksıdaki kaktüsü suluyor.', 'assets/terapi/s/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Sınıfta satranç yarışması yapıyorlar.', 'assets/terapi/s/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Prens prensesle dans ediyor.', 'assets/terapi/s/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Soner sosisli sandviç satıyor.', 'assets/terapi/s/cumle6.webp'),
    ]),
  ]),
  TerapiSes('Z', 'Kocaman gülümse. Dişlerini yavaşça birleştir. Dilini dişlerinin arkasına sakla. Şimdi boğazını titreştirerek arı gibi vızılda: Zzzzz!', 'assets/terapi/z/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('za', null),
      TerapiOge('zı', null),
      TerapiOge('zo', null),
      TerapiOge('zu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ze', null),
      TerapiOge('zi', null),
      TerapiOge('zö', null),
      TerapiOge('zü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aza', null),
      TerapiOge('ızı', null),
      TerapiOge('ozo', null),
      TerapiOge('uzu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eze', null),
      TerapiOge('izi', null),
      TerapiOge('özö', null),
      TerapiOge('üzü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('zar', 'assets/terapi/z/zar.webp'),
      TerapiOge('zil', 'assets/terapi/z/zil.webp'),
      TerapiOge('zarf', 'assets/terapi/z/zarf.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('zincir', 'assets/terapi/z/zincir.webp'),
      TerapiOge('zebra', 'assets/terapi/z/zebra.webp'),
      TerapiOge('zımba', 'assets/terapi/z/zimba.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('zencefil', 'assets/terapi/z/zencefil.webp'),
      TerapiOge('zeytinlik', 'assets/terapi/z/zeytinlik.webp'),
      TerapiOge('zürafa', 'assets/terapi/z/zurafa.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('yüzük', 'assets/terapi/z/yuzuk.webp'),
      TerapiOge('kızak', 'assets/terapi/z/kizak.webp'),
      TerapiOge('çizme', 'assets/terapi/z/cizme.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('ranza', 'assets/terapi/z/ranza.webp'),
      TerapiOge('kuzu', 'assets/terapi/z/kuzu.webp'),
      TerapiOge('cüzdan', 'assets/terapi/z/cuzdan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('gezegen', 'assets/terapi/z/gezegen.webp'),
      TerapiOge('kozalak', 'assets/terapi/z/kozalak.webp'),
      TerapiOge('şempanze', 'assets/terapi/z/sempanze.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('tuz', 'assets/terapi/z/tuz.webp'),
      TerapiOge('bez', 'assets/terapi/z/bez.webp'),
      TerapiOge('diz', 'assets/terapi/z/diz.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('horoz', 'assets/terapi/z/horoz.webp'),
      TerapiOge('havuz', 'assets/terapi/z/havuz.webp'),
      TerapiOge('sakız', 'assets/terapi/z/sakiz.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('ıstakoz', 'assets/terapi/z/istakoz.webp'),
      TerapiOge('sihirbaz', 'assets/terapi/z/sihirbaz.webp'),
      TerapiOge('mayonez', 'assets/terapi/z/mayonez.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('çizgili kazak', 'assets/terapi/z/cizgili_kazak.webp'),
      TerapiOge('kırmızı çizme', 'assets/terapi/z/kirmizi_cizme.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('deniz kızı', 'assets/terapi/z/deniz_kizi.webp'),
      TerapiOge('bezelye kavanozu', 'assets/terapi/z/bezelye_kavanozu.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('yaz sezonu', 'assets/terapi/z/yaz_sezonu.webp'),
      TerapiOge('zeytinli pizza', 'assets/terapi/z/zeytinli_pizza.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Zeynep denizde yüzüyor.', 'assets/terapi/z/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Benzinlikten benzin alıyor.', 'assets/terapi/z/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Madenci kazmayla kazıyor.', 'assets/terapi/z/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ziya buzda zor kayıyor.', 'assets/terapi/z/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Hizmetçi bezle temizlik yapıyor.', 'assets/terapi/z/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Zeki taze sebzeleri topluyor.', 'assets/terapi/z/cumle6.webp'),
    ]),
  ]),
  TerapiSes('Ş', 'Dudaklarını öne doğru uzat ve yuvarlak yap (kocaman bir öpücük verir gibi). Dişlerini birbirine yaklaştır. Şimdi dudaklarının arasından güçlü bir rüzgar üfle: Şşşş!', 'assets/terapi/sh/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('şa', null),
      TerapiOge('şı', null),
      TerapiOge('şo', null),
      TerapiOge('şu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('şe', null),
      TerapiOge('şi', null),
      TerapiOge('şö', null),
      TerapiOge('şü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aşa', null),
      TerapiOge('ışı', null),
      TerapiOge('oşo', null),
      TerapiOge('uşu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eşe', null),
      TerapiOge('işi', null),
      TerapiOge('öşö', null),
      TerapiOge('üşü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('şort', 'assets/terapi/sh/sort.webp'),
      TerapiOge('şal', 'assets/terapi/sh/sal.webp'),
      TerapiOge('şişe', 'assets/terapi/sh/sise.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('şapka', 'assets/terapi/sh/sapka.webp'),
      TerapiOge('şoför', 'assets/terapi/sh/sofor.webp'),
      TerapiOge('şişman', 'assets/terapi/sh/sisman.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('şemsiye', 'assets/terapi/sh/semsiye.webp'),
      TerapiOge('şempanze', 'assets/terapi/sh/sempanze.webp'),
      TerapiOge('şampuan', 'assets/terapi/sh/sampuan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('tişört', 'assets/terapi/sh/tisort.webp'),
      TerapiOge('aşçı', 'assets/terapi/sh/asci.webp'),
      TerapiOge('çeşme', 'assets/terapi/sh/cesme.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('paraşüt', 'assets/terapi/sh/parasut.webp'),
      TerapiOge('hemşire', 'assets/terapi/sh/hemsire.webp'),
      TerapiOge('gökkuşağı', 'assets/terapi/sh/gokkusagi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('taş', 'assets/terapi/sh/tas.webp'),
      TerapiOge('diş', 'assets/terapi/sh/dis.webp'),
      TerapiOge('kış', 'assets/terapi/sh/kis.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('kardeş', 'assets/terapi/sh/kardes.webp'),
      TerapiOge('güneş', 'assets/terapi/sh/gunes.webp'),
      TerapiOge('baykuş', 'assets/terapi/sh/baykus.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('kalemtıraş', 'assets/terapi/sh/kalemtiras.webp'),
      TerapiOge('arkadaş', 'assets/terapi/sh/arkadas.webp'),
      TerapiOge('heykeltıraş', 'assets/terapi/sh/heykeltiras.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('koşu yarışı', 'assets/terapi/sh/kosu_yarisi.webp'),
      TerapiOge('vişneli şurup', 'assets/terapi/sh/visneli_surup.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('şekerlikteki şeker', 'assets/terapi/sh/sekerlikteki_seker.webp'),
      TerapiOge('duş başlığı', 'assets/terapi/sh/dus_basligi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('şapkadaki tavşan', 'assets/terapi/sh/sapkadaki_tavsan.webp'),
      TerapiOge('şarkıcı Şafak', 'assets/terapi/sh/sarkici_safak.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Şuheda dişlerini kaşıyor.', 'assets/terapi/sh/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Yıkanmış çamaşırları asıyor.', 'assets/terapi/sh/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Şükrü şarkı söylüyor.', 'assets/terapi/sh/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Şapkadan şaşkın tavşan çıkıyor.', 'assets/terapi/sh/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('İşçi inşaata taş taşıyor.', 'assets/terapi/sh/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Şeyma hemşire aşı yapıyor.', 'assets/terapi/sh/cumle6.webp'),
    ]),
  ]),
  TerapiSes('J', 'Dudaklarını öne doğru uzat ve yuvarlak yap (kocaman bir öpücük verir gibi). Dişlerini birbirine yaklaştır. Şimdi boğazını titreterek güçlü bir ses çıkar: Jjjjj!', 'assets/terapi/j/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ja', null),
      TerapiOge('jı', null),
      TerapiOge('jo', null),
      TerapiOge('ju', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('je', null),
      TerapiOge('ji', null),
      TerapiOge('jö', null),
      TerapiOge('jü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aja', null),
      TerapiOge('ıjı', null),
      TerapiOge('ojo', null),
      TerapiOge('uju', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eje', null),
      TerapiOge('iji', null),
      TerapiOge('öjö', null),
      TerapiOge('üjü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('jip', 'assets/terapi/j/jip.webp'),
      TerapiOge('jet', 'assets/terapi/j/jet.webp'),
      TerapiOge('jöle', 'assets/terapi/j/jole.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('jokey', 'assets/terapi/j/jokey.webp'),
      TerapiOge('judo', 'assets/terapi/j/judo.webp'),
      TerapiOge('jaguar', 'assets/terapi/j/jaguar.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('jelibon', 'assets/terapi/j/jelibon.webp'),
      TerapiOge('jandarma', 'assets/terapi/j/jandarma.webp'),
      TerapiOge('jakuzi', 'assets/terapi/j/jakuzi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('oje', 'assets/terapi/j/oje.webp'),
      TerapiOge('pijama', 'assets/terapi/j/pijama.webp'),
      TerapiOge('deterjan', 'assets/terapi/j/deterjan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('ejderha', 'assets/terapi/j/ejderha.webp'),
      TerapiOge('oksijen', 'assets/terapi/j/oksijen.webp'),
      TerapiOge('alerji', 'assets/terapi/j/alerji.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('ruj', 'assets/terapi/j/ruj.webp'),
      TerapiOge('plaj', 'assets/terapi/j/plaj.webp'),
      TerapiOge('masaj', 'assets/terapi/j/masaj.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('baraj', 'assets/terapi/j/baraj.webp'),
      TerapiOge('garaj', 'assets/terapi/j/garaj.webp'),
      TerapiOge('makyaj', 'assets/terapi/j/makyaj.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('mesaj', 'assets/terapi/j/mesaj.webp'),
      TerapiOge('ambalaj', 'assets/terapi/j/ambalaj.webp'),
      TerapiOge('kamuflaj', 'assets/terapi/j/kamuflaj.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('şarjlı abajur', 'assets/terapi/j/sarjli_abajur.webp'),
      TerapiOge('jipin bagajı', 'assets/terapi/j/jipin_bagaji.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('ejderhalı pijama', 'assets/terapi/j/ejderhali_pijama.webp'),
      TerapiOge('hijyenik deterjan', 'assets/terapi/j/hijyenik_deterjan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('jokey Nejdet', 'assets/terapi/j/jokey_nejdet.webp'),
      TerapiOge('judocu Ajda', 'assets/terapi/j/judocu_ajda.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Jülide makyaj yapıyor.', 'assets/terapi/j/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Jale bileğini bandajlıyor.', 'assets/terapi/j/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Jip garajda duruyor.', 'assets/terapi/j/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Japon’un jelibona alerjisi var.', 'assets/terapi/j/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Müjgan judo, jimnastik yapıyor.', 'assets/terapi/j/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Nejat ile Tijen röportaj yapıyor.', 'assets/terapi/j/cumle6.webp'),
    ]),
  ]),
  TerapiSes('C', 'Dudaklarını öne doğru uzat (öpücük atar gibi). Dişlerini kapat. Şimdi boğazını titreterek ağzındaki havayı aniden patlat: Cccc!', 'assets/terapi/c/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ca', null),
      TerapiOge('cı', null),
      TerapiOge('co', null),
      TerapiOge('cu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ce', null),
      TerapiOge('ci', null),
      TerapiOge('cö', null),
      TerapiOge('cü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aca', null),
      TerapiOge('ıcı', null),
      TerapiOge('oco', null),
      TerapiOge('ucu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ece', null),
      TerapiOge('ici', null),
      TerapiOge('öcö', null),
      TerapiOge('ücü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('cam', 'assets/terapi/c/cam.webp'),
      TerapiOge('cep', 'assets/terapi/c/cep.webp'),
      TerapiOge('cin', 'assets/terapi/c/cin.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('cadı', 'assets/terapi/c/cadi.webp'),
      TerapiOge('cüce', 'assets/terapi/c/cuce.webp'),
      TerapiOge('ceket', 'assets/terapi/c/ceket.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('cetvel', 'assets/terapi/c/cetvel.webp'),
      TerapiOge('cezve', 'assets/terapi/c/cezve.webp'),
      TerapiOge('ceylan', 'assets/terapi/c/ceylan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('cüzdan', 'assets/terapi/c/cuzdan.webp'),
      TerapiOge('cambaz', 'assets/terapi/c/cambaz.webp'),
      TerapiOge('canavar', 'assets/terapi/c/canavar.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('baca', 'assets/terapi/c/baca.webp'),
      TerapiOge('böcek', 'assets/terapi/c/bocek.webp'),
      TerapiOge('ocak', 'assets/terapi/c/ocak.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('incir', 'assets/terapi/c/incir.webp'),
      TerapiOge('fincan', 'assets/terapi/c/fincan.webp'),
      TerapiOge('sincap', 'assets/terapi/c/sincap.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('macun', 'assets/terapi/c/macun.webp'),
      TerapiOge('cacık', 'assets/terapi/c/cacik.webp'),
      TerapiOge('tencere', 'assets/terapi/c/tencere.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('oyuncak', 'assets/terapi/c/oyuncak.webp'),
      TerapiOge('salıncak', 'assets/terapi/c/salincak.webp'),
      TerapiOge('öğrenci', 'assets/terapi/c/ogrenci.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('örümcek', 'assets/terapi/c/orumcek.webp'),
      TerapiOge('karınca', 'assets/terapi/c/karinca.webp'),
      TerapiOge('güvercin', 'assets/terapi/c/guvercin.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('lacivert gecelik', 'assets/terapi/c/lacivert_gecelik.webp'),
      TerapiOge('cesur kaleci', 'assets/terapi/c/cesur_kaleci.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('baloncu Cengiz', 'assets/terapi/c/baloncu_cengiz.webp'),
      TerapiOge('postacı güvercin', 'assets/terapi/c/postaci_guvercin.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('şekerci Cihan', 'assets/terapi/c/sekerci_cihan.webp'),
      TerapiOge('ocaktaki tencere', 'assets/terapi/c/ocaktaki_tencere.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Mercan oyuncakları inceliyor.', 'assets/terapi/c/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ceketin cebini dikiyor.', 'assets/terapi/c/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Karınca ağaca çıkıyor.', 'assets/terapi/c/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çekici turuncu aracı çekiyor.', 'assets/terapi/c/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ece’yi cırcır böceği ısırdı.', 'assets/terapi/c/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Caner düşünce bacağını incitti.', 'assets/terapi/c/cumle6.webp'),
    ]),
  ]),
  TerapiSes('Ç', 'Dudaklarını öne doğru uzat (öpücük atar gibi). Dişlerini kapat. Şimdi ağzında biriktirdiğin havayı aniden dışarı fırlat: Çççç!', 'assets/terapi/ch/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ça', null),
      TerapiOge('çı', null),
      TerapiOge('ço', null),
      TerapiOge('çu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('çe', null),
      TerapiOge('çi', null),
      TerapiOge('çö', null),
      TerapiOge('çü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aça', null),
      TerapiOge('ıçı', null),
      TerapiOge('oço', null),
      TerapiOge('uçu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eçe', null),
      TerapiOge('içi', null),
      TerapiOge('öçö', null),
      TerapiOge('üçü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('çay', 'assets/terapi/ch/cay.webp'),
      TerapiOge('çam', 'assets/terapi/ch/cam.webp'),
      TerapiOge('çöp', 'assets/terapi/ch/cop.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('çorba', 'assets/terapi/ch/corba.webp'),
      TerapiOge('çadır', 'assets/terapi/ch/cadir.webp'),
      TerapiOge('çatal', 'assets/terapi/ch/catal.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('çerçeve', 'assets/terapi/ch/cerceve.webp'),
      TerapiOge('çırpıcı', 'assets/terapi/ch/cirpici.webp'),
      TerapiOge('çikolata', 'assets/terapi/ch/cikolata.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('bekçi', 'assets/terapi/ch/bekci.webp'),
      TerapiOge('uçak', 'assets/terapi/ch/ucak.webp'),
      TerapiOge('aşçı', 'assets/terapi/ch/asci.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('bıçak', 'assets/terapi/ch/bicak.webp'),
      TerapiOge('çiçek', 'assets/terapi/ch/cicek.webp'),
      TerapiOge('çiftçi', 'assets/terapi/ch/ciftci.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('uçurtma', 'assets/terapi/ch/ucurtma.webp'),
      TerapiOge('palyaço', 'assets/terapi/ch/palyaco.webp'),
      TerapiOge('bahçıvan', 'assets/terapi/ch/bahcivan.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('saç', 'assets/terapi/ch/sac.webp'),
      TerapiOge('taç', 'assets/terapi/ch/tac.webp'),
      TerapiOge('vinç', 'assets/terapi/ch/vinc.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('pirinç', 'assets/terapi/ch/pirinc.webp'),
      TerapiOge('havuç', 'assets/terapi/ch/havuc.webp'),
      TerapiOge('yengeç', 'assets/terapi/ch/yengec.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('dalgıç', 'assets/terapi/ch/dalgic.webp'),
      TerapiOge('satranç', 'assets/terapi/ch/satranc.webp'),
      TerapiOge('saklambaç', 'assets/terapi/ch/saklambac.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('inatçı keçi', 'assets/terapi/ch/inatci_keci.webp'),
      TerapiOge('çamurlu çizme', 'assets/terapi/ch/camurlu_cizme.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('çaydanlıktaki çay', 'assets/terapi/ch/caydanliktaki_cay.webp'),
      TerapiOge('çilekli çikolata', 'assets/terapi/ch/cilekli_cikolata.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('ayçiçeği çekirdeği', 'assets/terapi/ch/aycicegi_cekirdegi.webp'),
      TerapiOge('palyaçonun saçı', 'assets/terapi/ch/palyaconun_saci.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çekiçle çivi çakıyor.', 'assets/terapi/ch/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çağla yengeçten kaçıyor.', 'assets/terapi/ch/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çetin çorba içiyor.', 'assets/terapi/ch/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çiğdemle Çınar uçurtma uçuruyor.', 'assets/terapi/ch/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Çocuklar büyüteçle çiçekleri inceliyor.', 'assets/terapi/ch/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Bahçıvan bahçedeki ağaçları suluyor.', 'assets/terapi/ch/cumle6.webp'),
    ]),
  ]),
  TerapiSes('H', 'Ağzını kocaman aç. Dilini rahat bırak, aşağıda yatsın. Şimdi sanki ellerin üşümüş de onları ısıtmak istiyormuşsun gibi içindeki sıcak havayı dışarı üfle: Hhhhh!', 'assets/terapi/h/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ha', null),
      TerapiOge('hı', null),
      TerapiOge('ho', null),
      TerapiOge('hu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('he', null),
      TerapiOge('hi', null),
      TerapiOge('hö', null),
      TerapiOge('hü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aha', null),
      TerapiOge('ıhı', null),
      TerapiOge('oho', null),
      TerapiOge('uhu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ehe', null),
      TerapiOge('ihi', null),
      TerapiOge('öhö', null),
      TerapiOge('ühü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('hap', 'assets/terapi/h/hap.webp'),
      TerapiOge('harf', 'assets/terapi/h/harf.webp'),
      TerapiOge('hız', 'assets/terapi/h/hiz.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('halka', 'assets/terapi/h/halka.webp'),
      TerapiOge('hindi', 'assets/terapi/h/hindi.webp'),
      TerapiOge('hamsi', 'assets/terapi/h/hamsi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('hokkabaz', 'assets/terapi/h/hokkabaz.webp'),
      TerapiOge('hamburger', 'assets/terapi/h/hamburger.webp'),
      TerapiOge('hazine', 'assets/terapi/h/hazine.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kahve', 'assets/terapi/h/kahve.webp'),
      TerapiOge('tahta', 'assets/terapi/h/tahta.webp'),
      TerapiOge('bahçe', 'assets/terapi/h/bahce.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('sihir', 'assets/terapi/h/sihir.webp'),
      TerapiOge('şahin', 'assets/terapi/h/sahin.webp'),
      TerapiOge('ahır', 'assets/terapi/h/ahir.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('ahududu', 'assets/terapi/h/ahududu.webp'),
      TerapiOge('ejderha', 'assets/terapi/h/ejderha.webp'),
      TerapiOge('kahraman', 'assets/terapi/h/kahraman.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('timsah', 'assets/terapi/h/timsah.webp'),
      TerapiOge('külah', 'assets/terapi/h/kulah.webp'),
      TerapiOge('sabah', 'assets/terapi/h/sabah.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('nikah', 'assets/terapi/h/nikah.webp'),
      TerapiOge('siyah', 'assets/terapi/h/siyah.webp'),
      TerapiOge('tesbih', 'assets/terapi/h/tesbih.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('bahçe hortumu', 'assets/terapi/h/bahce_hortumu.webp'),
      TerapiOge('horoz heykeli', 'assets/terapi/h/horoz_heykeli.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('hayvanat bahçesi', 'assets/terapi/h/hayvanat_bahcesi.webp'),
      TerapiOge('hazine haritası', 'assets/terapi/h/hazine_haritasi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('hastanın hapı', 'assets/terapi/h/hastanin_hapi.webp'),
      TerapiOge('tahin helvası', 'assets/terapi/h/tahin_helvasi.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Heykeltıraş heykel hazırlıyor.', 'assets/terapi/h/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Hulk halteri kaldırıyor.', 'assets/terapi/h/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kahvaltıya hamburger hazırlıyor.', 'assets/terapi/h/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Helikopter hızla sahaya indi.', 'assets/terapi/h/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Pahalı mücevher hediye ediyor.', 'assets/terapi/h/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Bahçıvan bahçeyi hortumla suluyor.', 'assets/terapi/h/cumle6.webp'),
    ]),
  ]),
  TerapiSes('Y', 'Hafifçe gülümse. Dilinin ortasını yukarı kaldır ama tavana değdirme. Şimdi sesini yumuşakça kaydırarak çıkar: Yyyyy!', 'assets/terapi/y/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ya', null),
      TerapiOge('yı', null),
      TerapiOge('yo', null),
      TerapiOge('yu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ye', null),
      TerapiOge('yi', null),
      TerapiOge('yö', null),
      TerapiOge('yü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('aya', null),
      TerapiOge('ıyı', null),
      TerapiOge('oyo', null),
      TerapiOge('uyu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('eye', null),
      TerapiOge('iyi', null),
      TerapiOge('öyö', null),
      TerapiOge('üyü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('yorgan', 'assets/terapi/y/yorgan.webp'),
      TerapiOge('yatak', 'assets/terapi/y/yatak.webp'),
      TerapiOge('yastık', 'assets/terapi/y/yastik.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('yengeç', 'assets/terapi/y/yengec.webp'),
      TerapiOge('yunus', 'assets/terapi/y/yunus.webp'),
      TerapiOge('yemek', 'assets/terapi/y/yemek.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('yarasa', 'assets/terapi/y/yarasa.webp'),
      TerapiOge('yarışma', 'assets/terapi/y/yarisma.webp'),
      TerapiOge('yumurta', 'assets/terapi/y/yumurta.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('ayı', 'assets/terapi/y/ayi.webp'),
      TerapiOge('ayna', 'assets/terapi/y/ayna.webp'),
      TerapiOge('bayrak', 'assets/terapi/y/bayrak.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kayak', 'assets/terapi/y/kayak.webp'),
      TerapiOge('koyun', 'assets/terapi/y/koyun.webp'),
      TerapiOge('meyve', 'assets/terapi/y/meyve.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('oyuncak', 'assets/terapi/y/oyuncak.webp'),
      TerapiOge('palyaço', 'assets/terapi/y/palyaco.webp'),
      TerapiOge('kaydırak', 'assets/terapi/y/kaydirak.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('yay', 'assets/terapi/y/yay.webp'),
      TerapiOge('çay', 'assets/terapi/y/cay.webp'),
      TerapiOge('tüy', 'assets/terapi/y/tuy.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('saray', 'assets/terapi/y/saray.webp'),
      TerapiOge('kaykay', 'assets/terapi/y/kaykay.webp'),
      TerapiOge('kovboy', 'assets/terapi/y/kovboy.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('mobilya', 'assets/terapi/y/mobilya.webp'),
      TerapiOge('dolunay', 'assets/terapi/y/dolunay.webp'),
      TerapiOge('battaniye', 'assets/terapi/y/battaniye.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('boy aynası', 'assets/terapi/y/boy_aynasi.webp'),
      TerapiOge('yüzücü mayosu', 'assets/terapi/y/yuzucu_mayosu.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('geyiğin boynuzu', 'assets/terapi/y/geyigin_boynuzu.webp'),
      TerapiOge('koyun yünü', 'assets/terapi/y/koyun_yunu.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('meyve suyu', 'assets/terapi/y/meyve_suyu.webp'),
      TerapiOge('siyah zeytin', 'assets/terapi/y/siyah_zeytin.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('İtfaiyeci yangını söndürüyor.', 'assets/terapi/y/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Yaman deney yapıyor.', 'assets/terapi/y/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Tiyatro oyunu oynadılar.', 'assets/terapi/y/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Yetenekli aşçı yemek yapıyor.', 'assets/terapi/y/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Yiğit aya ve yıldızlara bakıyor.', 'assets/terapi/y/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ayı yazın uykudan uyanıyor.', 'assets/terapi/y/cumle6.webp'),
    ]),
  ]),
  TerapiSes('L', 'Ağzını aç. Dilinin ucunu yukarı kaldır ve üst dişlerinin arkasındaki tavana sıkıca yapıştır. Dilini oradan hiç ayırmadan şarkı söyler gibi seslen: Lllll!', 'assets/terapi/l/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('la', null),
      TerapiOge('lı', null),
      TerapiOge('lo', null),
      TerapiOge('lu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('le', null),
      TerapiOge('li', null),
      TerapiOge('lö', null),
      TerapiOge('lü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ala', null),
      TerapiOge('ılı', null),
      TerapiOge('olo', null),
      TerapiOge('ulu', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ele', null),
      TerapiOge('ili', null),
      TerapiOge('ölö', null),
      TerapiOge('ülü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('lif', 'assets/terapi/l/lif.webp'),
      TerapiOge('lor', 'assets/terapi/l/lor.webp'),
      TerapiOge('lens', 'assets/terapi/l/lens.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('lale', 'assets/terapi/l/lale.webp'),
      TerapiOge('lokum', 'assets/terapi/l/lokum.webp'),
      TerapiOge('lastik', 'assets/terapi/l/lastik.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('lahana', 'assets/terapi/l/lahana.webp'),
      TerapiOge('lolipop', 'assets/terapi/l/lolipop.webp'),
      TerapiOge('lavabo', 'assets/terapi/l/lavabo.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kalem', 'assets/terapi/l/kalem.webp'),
      TerapiOge('balık', 'assets/terapi/l/balik.webp'),
      TerapiOge('balon', 'assets/terapi/l/balon.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('koltuk', 'assets/terapi/l/koltuk.webp'),
      TerapiOge('havlu', 'assets/terapi/l/havlu.webp'),
      TerapiOge('dolap', 'assets/terapi/l/dolap.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('helikopter', 'assets/terapi/l/helikopter.webp'),
      TerapiOge('bileklik', 'assets/terapi/l/bileklik.webp'),
      TerapiOge('salıncak', 'assets/terapi/l/salincak.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('gol', 'assets/terapi/l/gol.webp'),
      TerapiOge('fil', 'assets/terapi/l/fil.webp'),
      TerapiOge('çöl', 'assets/terapi/l/col.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('çatal', 'assets/terapi/l/catal.webp'),
      TerapiOge('davul', 'assets/terapi/l/davul.webp'),
      TerapiOge('okul', 'assets/terapi/l/okul.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('futbol', 'assets/terapi/l/futbol.webp'),
      TerapiOge('voleybol', 'assets/terapi/l/voleybol.webp'),
      TerapiOge('basketbol', 'assets/terapi/l/basketbol.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('aslan kral', 'assets/terapi/l/aslan_kral.webp'),
      TerapiOge('limonlu lolipop', 'assets/terapi/l/limonlu_lolipop.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('çikolata şelalesi', 'assets/terapi/l/cikolata_selalesi.webp'),
      TerapiOge('elmadaki tırtıl', 'assets/terapi/l/elmadaki_tirtil.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('kel oğlan', 'assets/terapi/l/kel_oglan.webp'),
      TerapiOge('balık kılçığı', 'assets/terapi/l/balik_kilcigi.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kaleci topları yakaladı.', 'assets/terapi/l/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Balarısı polen topluyor.', 'assets/terapi/l/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Palyaço balonları sallıyor.', 'assets/terapi/l/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Pilot uçakla bulutlarda dolaşıyor.', 'assets/terapi/l/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Pelikan gölde balık yakaladı.', 'assets/terapi/l/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Halıyı köpüklü suyla siliyor.', 'assets/terapi/l/cumle6.webp'),
    ]),
  ]),
  TerapiSes('R', 'Ağzını hafifçe aç. Dilinin ucunu yukarı kaldır (tavana doğru). Dilini sıkma, rahat bırak. Şimdi güçlü bir nefesle dilinin ucunu titret: Rrrrrr!', 'assets/terapi/r/yonerge.webp', [
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ra', null),
      TerapiOge('rı', null),
      TerapiOge('ro', null),
      TerapiOge('ru', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('re', null),
      TerapiOge('ri', null),
      TerapiOge('rö', null),
      TerapiOge('rü', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ara', null),
      TerapiOge('ırı', null),
      TerapiOge('oro', null),
      TerapiOge('uru', null),
    ]),
    TerapiEkran(TerapiAsama.heceler, null, [
      TerapiOge('ere', null),
      TerapiOge('iri', null),
      TerapiOge('örö', null),
      TerapiOge('ürü', null),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('raf', 'assets/terapi/r/raf.webp'),
      TerapiOge('ruj', 'assets/terapi/r/ruj.webp'),
      TerapiOge('ray', 'assets/terapi/r/ray.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('römork', 'assets/terapi/r/romork.webp'),
      TerapiOge('roket', 'assets/terapi/r/roket.webp'),
      TerapiOge('rende', 'assets/terapi/r/rende.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'BAŞTA', [
      TerapiOge('rengarenk', 'assets/terapi/r/rengarenk.webp'),
      TerapiOge('reçete', 'assets/terapi/r/recete.webp'),
      TerapiOge('rekabet', 'assets/terapi/r/rekabet.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('zırh', 'assets/terapi/r/zirh.webp'),
      TerapiOge('sirk', 'assets/terapi/r/sirk.webp'),
      TerapiOge('tart', 'assets/terapi/r/tart.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('kürdan', 'assets/terapi/r/kurdan.webp'),
      TerapiOge('kirpi', 'assets/terapi/r/kirpi.webp'),
      TerapiOge('tırtıl', 'assets/terapi/r/tirtil.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'ORTADA', [
      TerapiOge('yumurta', 'assets/terapi/r/yumurta.webp'),
      TerapiOge('trambolin', 'assets/terapi/r/trambolin.webp'),
      TerapiOge('kertenkele', 'assets/terapi/r/kertenkele.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('nar', 'assets/terapi/r/nar.webp'),
      TerapiOge('tır', 'assets/terapi/r/tir.webp'),
      TerapiOge('küre', 'assets/terapi/r/kure.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('incir', 'assets/terapi/r/incir.webp'),
      TerapiOge('gitar', 'assets/terapi/r/gitar.webp'),
      TerapiOge('çadır', 'assets/terapi/r/cadir.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeler, 'SONDA', [
      TerapiOge('anahtar', 'assets/terapi/r/anahtar.webp'),
      TerapiOge('traktör', 'assets/terapi/r/traktor.webp'),
      TerapiOge('bilgisayar', 'assets/terapi/r/bilgisayar.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('kar küresi', 'assets/terapi/r/kar_kuresi.webp'),
      TerapiOge('tren garı', 'assets/terapi/r/tren_gari.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('erik reçeli', 'assets/terapi/r/erik_receli.webp'),
      TerapiOge('dinozor yumurtası', 'assets/terapi/r/dinozor_yumurtasi.webp'),
    ]),
    TerapiEkran(TerapiAsama.kelimeGruplari, null, [
      TerapiOge('yarış arabası', 'assets/terapi/r/yaris_arabasi.webp'),
      TerapiOge('resim defteri', 'assets/terapi/r/resim_defteri.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Öğretmen ders anlatıyor.', 'assets/terapi/r/cumle1.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Sirkte gösteri yapıyorlar.', 'assets/terapi/r/cumle2.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Kurabiyeleri fırında pişiriyor.', 'assets/terapi/r/cumle3.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Türk bayrağı göklerde dalgalanıyor.', 'assets/terapi/r/cumle4.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Lunaparkta çarpışan arabalara biniyorlar.', 'assets/terapi/r/cumle5.webp'),
    ]),
    TerapiEkran(TerapiAsama.cumleler, null, [
      TerapiOge('Ramazan Bayramı’nda şeker topluyorlar.', 'assets/terapi/r/cumle6.webp'),
    ]),
  ]),
];
