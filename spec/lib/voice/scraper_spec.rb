require 'spec_helper'
require 'net/http'
require 'uri'

describe Voice::Scraper do
  describe '#extract_text' do
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
        expect(texts).to include(include('"シラサギ市南区"&<>'))
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
  end
end
