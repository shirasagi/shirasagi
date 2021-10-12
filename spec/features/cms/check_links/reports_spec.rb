require 'spec_helper'

describe "cms/check_links/reports", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:index) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "index.html", html: "" }
  let(:index_path) { cms_check_links_reports_path site.id }

  let(:page_count) { "#{I18n.t("ss.page")}0#{I18n.t("ss.units.count")}" }
  let(:node_count) { "#{I18n.t("ss.node")}0#{I18n.t("ss.units.count")}" }

  def execute_job
    Cms::CheckLinksJob.bind(site_id: site).perform_now
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      execute_job
      visit index_path
      within ".list-items" do
        expect(page).to have_selector('.list-item', count: 1)
      end

      execute_job
      visit index_path
      within ".list-items" do
        expect(page).to have_selector('.list-item', count: 2)
      end

      execute_job
      visit index_path
      within ".list-items" do
        expect(page).to have_selector('.list-item', count: 3)
      end

      execute_job
      visit index_path
      within ".list-items" do
        expect(page).to have_selector('.list-item', count: 4)
      end

      execute_job
      visit index_path
      within ".list-items" do
        expect(page).to have_selector('.list-item', count: 5)
      end

      execute_job
      visit index_path
      within ".list-items" do
        expect(page).to have_selector('.list-item', count: 5)
        first(".list-item a.title").click
      end

      within "#main" do
        expect(page).to have_css(".list-items", text: page_count)
      end

      within "#navi" do
        within first(".mod-navi") do
          click_on I18n.t("ss.node")
        end
      end

      within "#main" do
        expect(page).to have_css(".list-items", text: node_count)
      end
    end
  end
end
