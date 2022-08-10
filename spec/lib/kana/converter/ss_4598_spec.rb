require 'spec_helper'

describe Kana::Converter, dbscope: :example, mecab: true do
  let(:site) { create(:cms_site) }

  context "ss-4598" do
    let(:html) do
      <<~HTML
        <!doctype html>
        <html lang="ja">
        <body>
          <div>98%です。</div>
          <div>1,000人です。</div>
        </body>
        </html>
      HTML
    end

    it do
      result = described_class.kana_html(site, html)
      expect(result).to be_present

      fragment = Nokogiri::HTML.fragment(result)
      fragment.css("ruby").tap do |ruby_tags|
        expect(ruby_tags.length).to eq 1
        expect(ruby_tags[0].content).to eq "人(にん)"
      end
      fragment.css("div").tap do |div_tags|
        expect(div_tags.length).to eq 2
        expect(div_tags[0].content).to eq "98%です。"
        expect(div_tags[1].content).to eq "1,000人(にん)です。"
      end
    end
  end
end
