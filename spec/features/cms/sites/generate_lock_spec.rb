require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_site_path site.id }
  let(:now) { Time.zone.now.beginning_of_minute }

  around do |example|
    save_config = SS.config.cms.generate_lock
    SS::Config.replace_value_at(:cms, 'generate_lock', { 'disable' => false, 'options' => ['1.hour'] })
    travel_to(now) { example.run }
    SS::Config.replace_value_at(:cms, 'generate_lock', save_config)
  end

  describe "generate lock" do
    before { login_cms_user }

    it do
      visit index_path

      within "#addon-ss-agents-addons-generate_lock" do
        click_button I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_lock')
        expect(page).to have_no_selector('img')
      end

      site.reload
      expect(site.generate_lock_until).to be_present
      expect(site.generate_locked?).to be_truthy

      within "#addon-ss-agents-addons-generate_lock" do
        click_button I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_unlock')
        expect(page).to have_no_selector('img')
      end

      site.reload
      expect(site.generate_lock_until).to be_nil
      expect(site.generate_locked?).to be_falsey
    end
  end
end
