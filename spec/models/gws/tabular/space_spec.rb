require 'spec_helper'

describe Gws::Tabular::Space, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:space) { create :gws_tabular_space, cur_site: site, cur_user: user }

  describe 'help_url / help_url_en' do
    it 'saves both values' do
      space.update!(help_url: "https://example.jp/ja.pdf", help_url_en: "https://example.jp/en.pdf")
      space.reload
      expect(space.help_url).to eq "https://example.jp/ja.pdf"
      expect(space.help_url_en).to eq "https://example.jp/en.pdf"
    end

    it 'accepts http/https and blank' do
      %w(http://example.jp https://example.jp/manual.pdf).each do |url|
        space.help_url = url
        space.help_url_en = url
        expect(space).to be_valid
      end
      space.help_url = ""
      space.help_url_en = ""
      expect(space).to be_valid
    end

    it 'rejects invalid scheme / relative / scheme-less url (both fields)' do
      [ "javascript:alert(1)", "ftp://example.jp", "/relative/path", "https://" ].each do |url|
        space.help_url = url
        expect(space).not_to be_valid
        expect(space.errors[:help_url]).to be_present

        space.help_url = nil
        space.help_url_en = url
        expect(space).not_to be_valid
        expect(space.errors[:help_url_en]).to be_present
        space.help_url_en = nil
      end
    end
  end

  describe '#effective_help_url' do
    let(:ja_url) { "https://example.jp/ja.pdf" }
    let(:en_url) { "https://example.jp/en.pdf" }

    it 'returns help_url in Japanese UI' do
      space.update!(help_url: ja_url, help_url_en: en_url)
      I18n.with_locale(:ja) { expect(space.effective_help_url).to eq ja_url }
    end

    it 'prefers help_url_en in English UI, then falls back to help_url' do
      space.update!(help_url: ja_url, help_url_en: en_url)
      I18n.with_locale(:en) { expect(space.effective_help_url).to eq en_url }

      space.update!(help_url_en: nil)
      I18n.with_locale(:en) { expect(space.effective_help_url).to eq ja_url }
    end

    it 'returns nil when both are unset' do
      space.update!(help_url: nil, help_url_en: nil)
      I18n.with_locale(:ja) { expect(space.effective_help_url).to be_nil }
      I18n.with_locale(:en) { expect(space.effective_help_url).to be_nil }
    end
  end

  describe '#effective_help_url with a query projection (.only)' do
    # files/mains/trash の各コントローラは cur_space を .only(...) で読み込むため、
    # 投影に help_url_en が含まれないと、英語UIの effective_help_url で
    # Mongoid::Errors::AttributeNotLoaded が発生する（回帰ガード）。
    let(:projection) { %i[id i18n_name site_id i18n_description help_url help_url_en] }

    before { space.update!(help_url: "https://example.jp/ja.pdf", help_url_en: "https://example.jp/en.pdf") }

    it 'does not raise on a projected space in English UI' do
      projected = Gws::Tabular::Space.where(id: space.id).only(*projection).first
      I18n.with_locale(:en) do
        expect { projected.effective_help_url }.not_to raise_error
        expect(projected.effective_help_url).to eq "https://example.jp/en.pdf"
      end
    end

    it 'does not raise on a projected space in Japanese UI' do
      projected = Gws::Tabular::Space.where(id: space.id).only(*projection).first
      I18n.with_locale(:ja) do
        expect { projected.effective_help_url }.not_to raise_error
        expect(projected.effective_help_url).to eq "https://example.jp/ja.pdf"
      end
    end
  end

  it 'keeps localized name/description working together with help urls' do
    space.update!(help_url: "https://example.jp/manual.pdf")
    space.reload
    expect(space.name).to be_present
    expect(space.description).to be_present
    expect(space.help_url).to eq "https://example.jp/manual.pdf"
  end
end
