require 'spec_helper'

describe Gws::Addon::System::MenuSetting, type: :model, dbscope: :example do
  let(:site) { gws_site }

  context 'manual url (help_url / help_url_en)' do
    it 'saves help_url and help_url_en' do
      site.menu_memo_help_url = "https://example.jp/ja.pdf"
      site.menu_memo_help_url_en = "https://example.jp/en.pdf"
      site.save!
      site.reload
      expect(site.menu_memo_help_url).to eq "https://example.jp/ja.pdf"
      expect(site.menu_memo_help_url_en).to eq "https://example.jp/en.pdf"
    end

    it 'accepts http/https and blank' do
      %w(http://example.jp https://example.jp/manual.pdf).each do |url|
        site.menu_memo_help_url = url
        site.menu_memo_help_url_en = url
        expect(site).to be_valid
      end
      site.menu_memo_help_url = ""
      site.menu_memo_help_url_en = ""
      expect(site).to be_valid
    end

    it 'rejects invalid scheme / relative / scheme-less url (both fields)' do
      [ "javascript:alert(1)", "ftp://example.jp", "/relative/path", "https://" ].each do |url|
        site.menu_memo_help_url = url
        expect(site).not_to be_valid
        expect(site.errors[:menu_memo_help_url]).to be_present

        site.menu_memo_help_url = nil
        site.menu_memo_help_url_en = url
        expect(site).not_to be_valid
        expect(site.errors[:menu_memo_help_url_en]).to be_present
        site.menu_memo_help_url_en = nil
      end
    end

    describe '#menu_<module>_help_url_default' do
      it 'returns the Japanese default regardless of the current locale' do
        ja_default = I18n.t("gws/help.memo.manual_url", locale: :ja)
        expect(ja_default).to be_present
        I18n.with_locale(:ja) { expect(site.menu_memo_help_url_default).to eq ja_default }
        I18n.with_locale(:en) { expect(site.menu_memo_help_url_default).to eq ja_default }
      end

      it 'is nil for a menu without a default manual' do
        expect(site.menu_conf_help_url_default).to be_nil
      end
    end

    describe '#menu_<module>_effective_help_url' do
      let(:ja_url) { "https://example.jp/ja.pdf" }
      let(:en_url) { "https://example.jp/en.pdf" }
      let(:default_url) { I18n.t("gws/help.memo.manual_url", locale: :ja) }

      it 'Japanese UI: admin value preferred, else the default' do
        I18n.with_locale(:ja) do
          site.menu_memo_help_url = ja_url
          expect(site.menu_memo_effective_help_url).to eq ja_url

          site.menu_memo_help_url = nil
          expect(site.menu_memo_effective_help_url).to eq default_url
        end
      end

      it 'English UI: en -> ja -> default fallback order' do
        I18n.with_locale(:en) do
          site.menu_memo_help_url = ja_url
          site.menu_memo_help_url_en = en_url
          expect(site.menu_memo_effective_help_url).to eq en_url

          site.menu_memo_help_url_en = nil
          expect(site.menu_memo_effective_help_url).to eq ja_url

          site.menu_memo_help_url = nil
          expect(site.menu_memo_effective_help_url).to eq default_url
        end
      end

      it 'returns nil for a menu without value and without default' do
        I18n.with_locale(:en) { expect(site.menu_conf_effective_help_url).to be_nil }
      end
    end
  end

  context 'localized field normalization' do
    context 'when non-empty label is given' do
      let(:label) { unique_id }

      before do
        site.menu_portal_label = label
        site.save!
        site.reload
      end

      it do
        expect(site.menu_portal_label).to eq label
        expect(site.menu_portal_label_translations).to include(I18n.locale.to_s => label)
      end
    end

    context 'when empty label is given' do
      before do
        site.menu_portal_label = ''
        site.save!
        site.reload
      end

      it do
        expect(site.menu_portal_label).to be_nil
        expect(site.menu_portal_label_translations).to be_blank
      end
    end

    context 'when nil is given' do
      before do
        site.menu_portal_label = nil
        site.save!
        site.reload
      end

      it do
        expect(site.menu_portal_label).to be_nil
        expect(site.menu_portal_label_translations).to be_blank
      end
    end
  end

  context 'with en (fallback locale)' do
    let(:labels) do
      { 'en' => unique_id, 'ja' => '' }
    end
    let(:new_label) { unique_id }

    it do
      I18n.with_locale(:ja) do
        site.menu_portal_label_translations = labels
        site.save!

        site.reload
        # fallback to en
        expect(site.menu_portal_label).to eq labels['en']
        expect(site.menu_portal_label_translations).to include('en' => labels['en'])
        expect(site.menu_portal_label_translations).not_to have_key('ja')

        # overwrite at locale 'ja'
        site.menu_portal_label = new_label
        site.save!

        site.reload
        expect(site.menu_portal_label).to eq new_label
        expect(site.menu_portal_label).not_to eq labels['en']
        expect(site.menu_portal_label_translations).to include('en' => labels['en'])
        expect(site.menu_portal_label_translations).to have_key('ja')
      end
    end

    it do
      I18n.with_locale(:en) do
        site.menu_portal_label_translations = labels
        site.save!

        site.reload
        expect(site.menu_portal_label).to eq labels['en']
        expect(site.menu_portal_label_translations).to include('en' => labels['en'])
        expect(site.menu_portal_label_translations).not_to have_key('ja')

        # overwrite at locale 'en'
        site.menu_portal_label = new_label
        site.save!

        site.reload
        expect(site.menu_portal_label).to eq new_label
        expect(site.menu_portal_label).not_to eq labels['en']
        expect(site.menu_portal_label_translations).to include('en' => new_label)
        expect(site.menu_portal_label_translations).not_to have_key('ja')
      end
    end
  end

  context 'with zh-TW (non-fallback locale)' do
    let(:labels) do
      { 'zh-TW' => unique_id, 'ja' => '' }
    end
    let(:new_label) { unique_id }

    before do
      @save_enforce_available_locales = I18n.enforce_available_locales
    end

    after do
      I18n.enforce_available_locales = @save_enforce_available_locales if !@save_enforce_available_locales.nil?
      @save_enforce_available_locales = nil
    end

    it do
      I18n.enforce_available_locales = false
      I18n.with_locale(:ja) do
        site.menu_portal_label_translations = labels
        site.save!

        site.reload
        # fallback to en
        expect(site.menu_portal_label).to be_nil
        expect(site.menu_portal_label_translations).to include('zh-TW' => labels['zh-TW'])
        expect(site.menu_portal_label_translations).not_to have_key('ja')

        # overwrite at locale 'ja'
        site.menu_portal_label = new_label
        site.save!

        site.reload
        expect(site.menu_portal_label).to eq new_label
        expect(site.menu_portal_label_translations).to include('zh-TW' => labels['zh-TW'])
        expect(site.menu_portal_label_translations).to have_key('ja')
      end
    end

    it do
      I18n.enforce_available_locales = false
      I18n.with_locale(:'zh-TW') do
        site.menu_portal_label_translations = labels
        site.save!

        site.reload
        expect(site.menu_portal_label).to eq labels['zh-TW']
        expect(site.menu_portal_label_translations).to include('zh-TW' => labels['zh-TW'])
        expect(site.menu_portal_label_translations).not_to have_key('ja')

        # overwrite at locale 'en'
        site.menu_portal_label = new_label
        site.save!

        site.reload
        expect(site.menu_portal_label).to eq new_label
        expect(site.menu_portal_label).not_to eq labels['zh-TW']
        expect(site.menu_portal_label_translations).to include('zh-TW' => new_label)
        expect(site.menu_portal_label_translations).not_to have_key('ja')
      end
    end
  end
end
