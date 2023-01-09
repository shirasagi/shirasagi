require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_generate_lock_path site.id }
  let(:now) { Time.zone.now.beginning_of_minute }

  around do |example|
    save_config = SS.config.cms.generate_lock
    SS.config.replace_value_at(:cms, 'generate_lock', { 'disable' => false, 'generate_lock_until' => '1.hour' })
    travel_to(now) { example.run }
    SS.config.replace_value_at(:cms, 'generate_lock', save_config)
  end

  describe "generate lock" do
    before { login_cms_user }

    it do
      visit index_path

      within "form#item-form" do
        fill_in_datetime "item[generate_lock_until]", with: Time.zone.now + 1.hour
        click_button I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_lock')
      end
      expect(page).to have_no_css("div#errorExplanation")
      site.reload
      expect(site.generate_lock_until).to be_present
      expect(site.generate_locked?).to be_truthy

      within "form#item-form" do
        fill_in_datetime "item[generate_lock_until]", with: nil
        click_button I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_lock')
      end
      expect(page).to have_no_css("div#errorExplanation")
      site.reload
      expect(site.generate_lock_until).to be_nil
      expect(site.generate_locked?).to be_falsey

      within "form#item-form" do
        fill_in_datetime "item[generate_lock_until]", with: Time.zone.now + 2.hours
        click_button I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_lock')
      end
      msg = site.t(:generate_lock_until) + I18n.t('mongoid.errors.models.ss/addon/generate_lock.disallow_datetime_by_system')
      expect(page).to have_css("div#errorExplanation", text: msg)
      site.reload
      expect(site.generate_lock_until).to be_nil
      expect(site.generate_locked?).to be_falsey

      within "form#item-form" do
        fill_in_datetime "item[generate_lock_until]", with: Time.zone.now + 15.minutes
        click_button I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_lock')
      end
      expect(page).to have_no_css("div#errorExplanation")
      site.reload
      expect(site.generate_lock_until).to be_present
      expect(site.generate_locked?).to be_truthy

      within "form#item-form" do
        click_button I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_unlock')
      end
      expect(page).to have_no_css("div#errorExplanation")
      site.reload
      expect(site.generate_lock_until).to be_nil
      expect(site.generate_locked?).to be_falsey
    end
  end
end
