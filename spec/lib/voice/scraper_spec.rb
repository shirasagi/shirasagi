require 'spec_helper'
require 'net/http'
require 'uri'

describe Voice::Scraper do
  context "when typical html is given" do
    source_file = ::File.new("#{Rails.root}/spec/fixtures/voice/test-001.html")
    html = source_file.read
    scraper = Voice::Scraper.new
    texts = scraper.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'has more then 3 items' do
      expect(texts.length).to be > 3
    end
    it 'contains "市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。"' do
      expect(texts).to include(include("市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。"))
    end
    it 'contains "平田 13μg/㎥。"' do
      expect(texts).to include(include("平田 13μg/㎥。"))
    end
    it 'contains "シラサギ市南区"' do
      expect(texts).to include(include("シラサギ市南区"))
    end
    it 'does not contain "本文へ"' do
      expect(texts).not_to include(include("本文へ"))
    end
    it 'does not contain "カテゴリー"' do
      expect(texts).not_to include(include("カテゴリー"))
    end
    it 'contains "掛色公園" of "<img>"' do
      expect(texts).to include(include("画像 掛色公園"))
    end
    it 'contains "旭下海岸" of "<img>"' do
      expect(texts).to include(include("画像 旭下海岸"))
    end
    it 'contains "塩清学園" of "<img>"' do
      expect(texts).to include(include("画像 塩清学園"))
    end
    it 'does not contain "function"' do
      expect(texts).not_to include(include("function"))
    end
    it 'does not contain "google-analytics"' do
      expect(texts).not_to include(include("google-analytics"))
    end
  end

  context "when no read-voice marked and id='main' marked html is given" do
    source_file = ::File.new("#{Rails.root}/spec/fixtures/voice/test-001.html")
    html = source_file.read
    # remove "read-voice"
    html.gsub!(/(end-)?read-voice/, "")
    html.gsub!(/(end-)?skip-voice/, "")
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'has more then 3 items' do
      expect(texts.length).to be > 3
    end
    it 'contains "市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。"' do
      expect(texts).to include(include("市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。"))
    end
    it 'contains "平田　13μg/㎥。"' do
      expect(texts).to include(include("平田 13μg/㎥。"))
    end
    it 'contains "本文へ"' do
      expect(texts).to include(include("本文へ"))
    end
    it 'contains "カテゴリー"' do
      expect(texts).to include(include("カテゴリー"))
    end
  end

  context "when <script> is given" do
    html = <<-EOF
              <html>
                <body>
                  <script>
                    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
                    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
                    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
                    ga('create', 'UA-54709760-1', 'auto');
                    ga('send', 'pageview');
                  </script>
                </body>
              </html>
    EOF
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'is empty' do
      expect(texts.length).to eq 0
    end
  end

  context "when <script type=\"text/javascript\"> is given" do
    source_file = ::File.new("#{Rails.root}/spec/fixtures/voice/test-002.html")
    html = source_file.read
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'is empty' do
      expect(texts.length).to eq 0
    end
  end

  context "when http entity &rsaquo; is given" do
    html = "<p>&rsaquo;</p>"
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'is empty' do
      expect(texts.length).to eq 0
    end
  end

  context "when http entity &sup2; is given" do
    html = "<p>&sup2;</p>"
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'is empty' do
      expect(texts.length).to eq 0
    end
  end

  context "when http entity &Eacute; is given" do
    html = "<p>&Eacute;</p>"
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'is empty' do
      expect(texts.length).to eq 0
    end
  end

  context "when http entity &#174; is given" do
    html = "<p>&#174;</p>"
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'is empty' do
      expect(texts.length).to eq 0
    end
  end

  context "when multiple skip-voice is given" do
    source_file = ::File.new("#{Rails.root}/spec/fixtures/voice/test-003.html")
    html = source_file.read
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'contains "見出し1"' do
      expect(texts).to include(include("見出し1"))
    end
    it 'contains "見出し2"' do
      expect(texts).to include(include("見出し2"))
    end
    it 'contains "見出し3"' do
      expect(texts).to include(include("見出し3"))
    end
    it 'contains "見出し4"' do
      expect(texts).to include(include("見出し4"))
    end
    it 'contains "内容が入ります。内容が入ります。内容が入ります。"' do
      expect(texts).to include(include("内容が入ります。内容が入ります。内容が入ります。"))
    end
  end

  context "when if it IE7 comment is given" do
    source_file = ::File.new("#{Rails.root}/spec/fixtures/voice/test-003.html")
    html = source_file.read
    texts = Voice::Scraper.new.extract_text html

    it 'is array' do
      expect(texts).to be_a(Array)
    end
    it 'does not contain "あなたは旧式ブラウザをご利用中です"' do
      expect(texts).not_to include(include("あなたは旧式ブラウザをご利用中です"))
    end
    it 'does not contain "このウェブサイトを快適に閲覧するにはブラウザをアップグレードしてください。"' do
      expect(texts).not_to include(include("このウェブサイトを快適に閲覧するにはブラウザをアップグレードしてください"))
    end
    it 'does not contain "Get Firefox 3.5"' do
      expect(texts).not_to include(include("Get Firefox 3.5"))
    end
    it 'does not contain "Get Internet Explorer 8"' do
      expect(texts).not_to include(include("Get Internet Explorer 8"))
    end
    it 'does not contain "Get Safari 4"' do
      expect(texts).not_to include(include("Get Safari 4"))
    end
    it 'does not contain "Get Google Chrome"' do
      expect(texts).not_to include(include("Get Google Chrome"))
    end
  end
end
