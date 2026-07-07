require 'spec_helper'

describe Kana::Converter, dbscope: :example, mecab: true do
  let!(:site) { create :cms_site }

  context "絵文字（UTF-8で4バイト以上）で位置がずれてしまい Kana::ConvertError が発生" do
    let!(:html) do
      fixture_file = "#{Rails.root}/spec/fixtures/kana/test_emoji.html"
      File.read(fixture_file)
    end

    it do
      result = described_class.kana_html(site, html)
      expect(result).to be_present

      fragment = Nokogiri::HTML.fragment(result)
      expect(fragment.css("h2 ruby")[0].content).to include("けんすう")
    end
  end
end
