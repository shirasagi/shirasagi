require 'spec_helper'

describe "cms/check_links/ignore_urls", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:item) { create :check_links_ignore_url }
  let!(:url) { "http://sample.example.jp" }
  let!(:kind) { %w(all start_with end_with include).sample }
  let!(:kind_label) { I18n.t("cms.options.ignore_url_kind.#{kind}") }

  let(:index_path) { cms_check_links_ignore_urls_path(site: site.id) }
  let(:new_path) { new_cms_check_links_ignore_url_path(site: site.id) }
  let(:show_path) { cms_check_links_ignore_url_path(site: site.id, id: item.id) }
  let(:edit_path) { edit_cms_check_links_ignore_url_path(site: site.id, id: item.id) }
  let(:delete_path) { delete_cms_check_links_ignore_url_path(site: site.id, id: item.id) }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: url
        select kind_label, from: "item[kind]"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-basic" do
        expect(page).to have_text(url)
        expect(page).to have_text(kind_label)
      end
    end

    it "#show" do
      visit show_path
      within "#addon-basic" do
        expect(page).to have_text(item.name)
        expect(page).to have_text(item.label(:kind))
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: url
        select kind_label, from: "item[kind]"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-basic" do
        expect(page).to have_text(url)
        expect(page).to have_text(kind_label)
      end
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end
end
