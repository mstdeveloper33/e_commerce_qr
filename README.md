E-Commerce QR & Product Auto-Enrichment
Amaç: Barkoda göre ürün arayıp; ürün başlığı, fiyatı, görseli ve AI destekli kısa/uzun açıklama + SEO etiketleri oluşturarak veriyi Supabase/Postgres’e kaydeden, No-Code/Low-Code n8n tabanlı otomasyon.

İçindekiler
Mimari Genel Bakış

Özellikler

Teknolojiler

Akış (n8n)

Hızlı Başlangıç

Kurulum & Yapılandırma

Veri Şeması (Supabase/Postgres)

Örnek Webhook Yükü

Güvenlik Notları

Yasal Uyarı (Scraping)

Sorun Giderme

Yol Haritası

Katkı

Lisans

Mimari Genel Bakış
mermaid
Kopyala
Düzenle
flowchart LR
  A[Flutter Mobil Uygulama\n(Barkod Okuma)] -->|code| B[Webhook (n8n)]
  B --> C[Trendyol/Hepsiburada/n11\nHTML Fetch (Jina Reader)]
  C --> D[AI Bilgi Çıkarımı\n(Information Extractor)]
  D --> E{Ürün Bulundu mu?}
  E -- Evet --> F[Resim URL uzantısı çıkar]
  F --> G[Alan Düzenleme (Set)]
  G --> H[(Postgres / Supabase)]
  E -- Hayır --> I[Sonlandır / Alternatif Kaynak Dene]
Flutter: Barkodu okur, Webhook’a gönderir.

n8n: Jina Reader ile HTML’yi çeker → AI extractor ile ilk ürün verisini normalize eder → görsel uzantısını ayrıştırır → Postgres/Supabase’e yazar.

OpenAI (Agent/Model): Kısa/uzun açıklama ve SEO etiket üretimi.

Jina Reader: HTML sayfalarını hızlı ve sade metne çevirerek AI çıkarımı için besler.

Özellikler
🔎 Barkoda göre ürün arama (Trendyol, Hepsiburada, n11 — kolayca genişletilebilir)

🧠 AI tabanlı kısa açıklama, uzun açıklama ve SEO uyumlu etiket üretimi

🖼️ Ürün görseli URL’si ve format çıkarımı (.jpg/.jpeg/.png/.webp)

💾 Veritabanına (Supabase/Postgres) otomatik kayıt

⚙️ n8n ile No-Code/Low-Code orkestrasyon

🔌 Modüler, kolay genişletilebilir kaynak/site entegrasyonu

🧰 Google Sheets’e alternatif kayıt desteği (opsiyonel)

Teknolojiler
n8n (Otomasyon/Orkestrasyon)

Flutter (Mobil barkod okuma)

OpenAI (LLM / Agent — gpt-4o-mini)

Jina (Jina Reader: https://r.jina.ai/https://...)

Supabase / PostgreSQL (kalıcı saklama)

Akış (n8n)
Repo: N8n/n8n.json

Temel nodelar:

Webhook → barkod (code) alır.

HTTP Request → Jina Reader ile site içeriğini çeker:

Trendyol: https://r.jina.ai/https://www.trendyol.com/sr?q={{code}}&qt={{code}}&st={{code}}&os=1

n11: https://r.jina.ai/https://www.n11.com/arama?q={{code}}

Hepsiburada: https://r.jina.ai/https://www.hepsiburada.com/ara?q={{code}}

Information Extractor → yalnızca ilk ürün için normalize JSON çıkarır (status, title, url, product{...}).

If → bulundu mu?

Code → görsel uzantısı ayrıştırma.

Set → alanları düzenleme (output, file_name, barcode vb.)

Postgres → ProductTable tablosuna yazma.

Not: Workflow, n8n credential referanslarını kullanır (API key’ler JSON’da düz metin bulunmaz).

Hızlı Başlangıç
bash
Kopyala
Düzenle
# 1) Repoyu al
git clone https://github.com/mstdeveloper33/e_commerce_qr.git
cd e_commerce_qr

# 2) n8n'i yerel çalıştır (Docker önerilir)
docker run -it --rm \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# 3) n8n arayüzüne gir (http://localhost:5678) ve
#    N8n/n8n.json dosyasını "Import" ile içe aktar
Credentials:

OpenAI API (model: gpt-4o-mini)

Postgres/Supabase bağlantısı

Webhook: n8n → URL’i kopyalayın (örn: POST https://.../webhook/feb5e803-cbe9-...)

Kurulum & Yapılandırma
1) OpenAI
n8n > Credentials > OpenAI

API Key: OPENAI_API_KEY

Model: gpt-4o-mini (workflow içinde tanımlı)

2) Postgres / Supabase
Supabase kullanıyorsanız:

Project Settings > Database’ten host/port/db/user/password alın.

n8n > Credentials > Postgres oluşturun (SSL gerekiyorsa işaretleyin).

3) Flutter Mobil
Barkodu okur, Webhook’a şu gövdede POST atar:

json
Kopyala
Düzenle
{
  "code": "8690216120122"
}
Not: Webhook path workflow dosyasında "path": "feb5e803-cbe9-47e7-9abd-79f741100d47" şeklindedir. Kendi ortamınızda n8n bu path’i değiştirebilir; import sonrası n8n arayüzünden URL’yi doğrulayın.

Veri Şeması (Supabase/Postgres)
Önerilen tablo: public."ProductTable"

sql
Kopyala
Düzenle
create table if not exists public."ProductTable" (
  id bigserial primary key,
  created_at timestamptz default now(),
  title text,
  url text,
  product jsonb,
  barcode text,
  file_name text
);

-- Sorgu performansı için opsiyonel index
create index if not exists idx_producttable_barcode on public."ProductTable"(barcode);
product alanı, aşağıdaki normalize JSON yapısını tutar.

Örnek Webhook Yükü
İstek (Flutter → n8n Webhook):

bash
Kopyala
Düzenle
curl -X POST https://<SIZIN-N8N-URLINIZ>/webhook/<path> \
  -H "Content-Type: application/json" \
  -d '{"code":"4005402548316"}'
AI Extractor Çıktısı (örnek):

json
Kopyala
Düzenle
{
  "status": true,
  "title": "Faber-Castell Textliner 4'lü",
  "url": "https://www.trendyol.com/...",
  "product": {
    "id": "ofisfab8316",
    "name": "Faber Castell Textliner Fosforlu Kalem 4'lü",
    "price": "199 TL",
    "rating": "4.6",
    "reviews_count": "354",
    "category": "Kırtasiye / Ofis",
    "brand": "Faber-Castell",
    "discount": null,
    "image": "https://productimages.hepsiburada.net/s/777/222-222/110000685181957.jpg"
  }
}
Not: Ürün bulunamazsa status:false ve diğer alanlar null döndürülür (workflow’daki şema kurallarına göre).

Güvenlik Notları
API anahtarlarını kesinlikle repoya commit etmeyin.

n8n’de Credentials kullanın; .env değerleri Docker secret/host env üzerinden geçsin.

Supabase/Postgres erişim izinlerini IP kısıtlama/SSL ile sınırlandırın.

Webhook için gizli path + gerekirse HMAC imza/temel auth ekleyin.

Rate limit ve retry/backoff stratejisi uygulayın.

Yasal Uyarı (Scraping)
Hedef sitelerin kullanım şartları (ToS) ve robots.txt kurallarına uyun.

Yalnızca izin verilen sayfaları ve kamuya açık verileri çekin.

Ticari kullanım planlıyorsanız önceden yazılı izin alın.

İstek oranlarını sınırlayın; sitelerin hizmetlerini olumsuz etkilemeyin.

Sorun Giderme
Webhook 404/401: n8n import sonrası path değişmiş olabilir; URL’yi yeniden kopyalayın.

Boş sonuç: Jina Reader URL’leri (r.jina.ai) doğru mu? Kod parametresi düzgün geliyor mu?

Veritabanı hatası: Postgres credential ve tablo şeması eşleşiyor mu? SSL gerekiyorsa açın.

Görsel URL uzantısı: Sadece .jpg/.jpeg/.png/.webp kabul edilir; farklı uzantılarda filtre ekleyin.

Model hatası: OpenAI kredileri/limiti, model adı ve bölge ayarlarını kontrol edin.

Yol Haritası
 Google Sheets’e doğrudan yazan alternatif akış

 Fiyat geçmişi & karşılaştırma grafikleri

 Birden fazla dilde açıklama/etiket üretimi

 Ürün varyant/satıcı konsolidasyonu

 Admin panel (filtreleme/iyileştirme/yeniden işleme)

Katkı
PR’lar, issue’lar ve öneriler memnuniyetle karşılanır. Büyük değişikliklerde önce bir issue açıp tartışalım.

Lisans
MIT 
