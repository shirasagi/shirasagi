require 'spec_helper'

describe "cms_roles", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:item) { Cms::Role.last }
  subject(:index_path) { cms_roles_path site.id }
  subject(:new_path) { new_cms_role_path site.id }
  subject(:show_path) { cms_role_path site.id, item }
  subject(:edit_path) { edit_cms_role_path site.id, item }
  subject(:delete_path) { delete_cms_role_path site.id, item }
  subject(:import_path) { import_cms_roles_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        #check "item[permissions][]"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "#import" do
      visit import_path
      within "form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/cms/role/cms_roles_1.csv"
        click_button I18n.t('ss.buttons.import')
      end
      expect(status_code).to eq 200
      wait_for_notice I18n.t("ss.notice.started_import")

      expect(enqueued_jobs.length).to eq 1
      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Cms::Role::ImportJob
        expect(enqueued_job[:args]).to be_present
        expect(enqueued_job[:args]).to have(1).items
        # file id
        expect(enqueued_job[:args][0]).to be_present
      end
    end
  end
end
