require 'spec_helper'

describe "cms/check_links/ignore_urls", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:url) { "http://sample.example.jp" }
  let(:item) { create(:check_links_ignore_url, name: url) }

  let!(:layout) { create_cms_layout }
  let!(:index) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "index.html", html: html1 }

  let!(:html1) do
    h = []
    h << '<a href="' + url + '">index</a>'
    h.join("\n")
  end

  let(:index_path) { cms_check_links_ignore_urls_path(site: site.id) }
  let(:new_path) { new_cms_check_links_ignore_url_path(site: site.id) }
  let(:show_path) { cms_check_links_ignore_url_path(site: site.id, id: item.id) }
  let(:edit_path) { edit_cms_check_links_ignore_url_path(site: site.id, id: item.id) }
  let(:delete_path) { delete_cms_check_links_ignore_url_path(site: site.id, id: item.id) }

  def execute_job
    Cms::CheckLinksJob.bind(site_id: site).perform_now
  end

  def latest_report
    Cms::CheckLinks::Report.site(site).first
  end

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end

  context "ignore link error" do
    before { login_cms_user }

    it "#index" do
      execute_job
      expect(latest_report.pages.size).to eq 1

      item

      execute_job
      expect(latest_report.pages.size).to eq 0
    end
  end
end
