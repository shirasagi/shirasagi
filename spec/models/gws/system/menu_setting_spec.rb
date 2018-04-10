require 'spec_helper'

describe Gws::Addon::System::MenuSetting, type: :model, dbscope: :example do
  let(:site) { gws_site }

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

    before do
      @save_locale = I18n.locale
    end

    after do
      I18n.locale = @save_locale if @save_locale
      @save_locale = nil
    end

    it do
      I18n.locale = :ja

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

    it do
      I18n.locale = :en

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

  context 'with zh-TW (non-fallback locale)' do
    let(:labels) do
      { 'zh-TW' => unique_id, 'ja' => '' }
    end
    let(:new_label) { unique_id }

    before do
      @save_enforce_available_locales = I18n.enforce_available_locales
      @save_locale = I18n.locale
    end

    after do
      I18n.locale = @save_locale if @save_locale
      I18n.enforce_available_locales = @save_enforce_available_locales if !@save_enforce_available_locales.nil?

      @save_enforce_available_locales = nil
      @save_locale = nil
    end

    it do
      I18n.enforce_available_locales = false
      I18n.locale = :ja

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

    it do
      I18n.enforce_available_locales = false
      I18n.locale = 'zh-TW'.to_sym

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
