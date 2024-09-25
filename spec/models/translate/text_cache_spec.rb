require 'spec_helper'

describe Translate::TextCache, dbscope: :example do
  let!(:site) { cms_site }

  context "サイトが同じ場合、同じ翻訳結果を登録することができない / unable to save same translation result on the same sites" do
    let(:api) { %w(google_translation microsoft_translator_text).sample }
    let(:update_state) { %w(auto manually).sample }
    let(:text) { unique_id }
    let(:original_text) { unique_id }
    let(:source) { "ja" }
    let(:target) { "en" }

    it do
      Translate::TextCache.create!(
        cur_site: site, api: api, update_state: update_state, text: text, original_text: original_text,
        source: source, target: target)
      expectation = expect do
        Translate::TextCache.create!(
          cur_site: site, api: api, update_state: update_state, text: text, original_text: original_text,
          source: source, target: target)
      end
      expectation.to raise_error Mongoid::Errors::Validations
    end
  end

  # 「自動翻訳結果を手動で修正することで誤翻訳を修正する」というユースケースを考慮すると、翻訳結果はサイトごとに保存できるようにするべき。
  context "サイトが異なる場合、同じ翻訳結果を登録することができる / Different sites are able to have same translation result" do
    let!(:site1) { create :cms_site_unique }
    let!(:site2) { create :cms_site_unique }
    let(:api) { "microsoft_translator_text" }
    let(:update_state) { "auto" }
    let(:text) { unique_id }
    let(:original_text) { unique_id }
    let(:source) { "ja" }
    let(:target) { "en" }

    it do
      text_cache1 = Translate::TextCache.create!(
        cur_site: site1, api: api, update_state: update_state, text: text, original_text: original_text,
        source: source, target: target)
      text_cache2 = Translate::TextCache.create!(
        cur_site: site2, api: api, update_state: update_state, text: text, original_text: original_text,
        source: source, target: target)

      expect(text_cache1).to be_valid
      expect(text_cache2).to be_valid
      expect(text_cache2.hexdigest).to eq text_cache1.hexdigest
    end
  end
end
