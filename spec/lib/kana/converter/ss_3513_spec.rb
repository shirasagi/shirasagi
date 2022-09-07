require 'spec_helper'

describe Kana::Converter, dbscope: :example, mecab: true do
  let(:site) { create(:cms_site) }

  context "ss-3513" do
    let(:html) do
      <<~HTML
        <!doctype html>
        <html lang="ja">
        <head>
          <title>&amp;times;× -  Site</title>
        </head>
        <body>
          <span class="percent-escaped-url">http%3A%2F%2F127.0.0.1%3A3000</span>
          <a href="https://get.adobe.com/jp/reader/" class="adobe">Adobe Readerをダウンロードする</a>
        </body>
        </html>
      HTML
    end

    it do
      result = described_class.kana_html(site, html)
      expect(result).to be_present

      fragment = Nokogiri::HTML.fragment(result)
      expect(fragment.css(".percent-escaped-url")[0].content).to eq "http%3A%2F%2F127.0.0.1%3A3000"
      fragment.css(".adobe")[0].tap do |adobe_tag|
        expect(adobe_tag.content).to eq "Adobe Readerをダウンロードする"
        expect(adobe_tag.attributes["href"].value).to eq "https://get.adobe.com/jp/reader/"
      end
    end
  end
end
