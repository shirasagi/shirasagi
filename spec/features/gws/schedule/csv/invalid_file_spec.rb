require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "with empty file" do
    it do
      visit gws_schedule_csv_path(site: site)
      within "form#import_form" do
        page.accept_confirm do
          click_on I18n.t("ss.import")
        end
      end

      expect(page).to have_css("div.mb-1", text: I18n.t('ss.errors.import.blank_file'))
    end
  end

  context "with png file" do
    it do
      visit gws_schedule_csv_path(site: site)
      within "form#import_form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        page.accept_confirm do
          click_on I18n.t("ss.import")
        end
      end

      expect(page).to have_css("div.mb-1", text: I18n.t('ss.errors.import.invalid_file_type'))
    end
  end

  context "with invalid csv file" do
    it do
      visit gws_schedule_csv_path(site: site)
      within "form#import_form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/role/cms_roles_1.csv"
        page.accept_confirm do
          click_on I18n.t("ss.import")
        end
      end

      expect(page).to have_css("div.mb-1", text: I18n.t('ss.errors.import.invalid_file_type'))
    end
  end
end
