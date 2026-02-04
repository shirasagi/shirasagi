require 'spec_helper'

describe "cms_preview", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node1) { create :cms_node_node, layout: layout, filename: "node" }
  let!(:node2) { create :article_node_page, layout: layout, filename: "docs" }
  let!(:part) { create :article_part_page, filename: "docs/part" }
  let!(:layout) { create_cms_layout part }

  let!(:now) { Time.zone.now }
  let!(:release_date1) { now.advance(days: 1) }
  let!(:release_date2) { now.advance(days: 2) }

  let!(:item1) { create :article_page, cur_node: node2, layout: layout, release_date: release_date1 }
  let!(:item2) { create :article_page, cur_node: node2, layout: layout, release_date: release_date2 }
  let!(:item3) { create :article_page, cur_node: node2, layout: layout }

  context "pc preview" do
    before { login_cms_user }

    let(:preview_path) { cms_preview_path(site: site, path: node1.filename + "/") }

    it do
      visit preview_path
      wait_for_js_ready

      expect(page).to have_no_link(item1.name)
      expect(page).to have_no_link(item2.name)
      expect(page).to have_link(item3.name)

      within ".ss-preview-wrap" do
        fill_in_datetime "ss-preview-date", with: now
        click_on I18n.t("cms.preview_page")
      end
      wait_for_js_ready

      expect(page).to have_no_link(item1.name)
      expect(page).to have_no_link(item2.name)
      expect(page).to have_link(item3.name)

      within ".ss-preview-wrap" do
        fill_in_datetime "ss-preview-date", with: (release_date1 + 1.minute)
        click_on I18n.t("cms.preview_page")
      end
      wait_for_js_ready

      expect(page).to have_link(item1.name)
      expect(page).to have_no_link(item2.name)
      expect(page).to have_link(item3.name)

      within ".ss-preview-wrap" do
        fill_in_datetime "ss-preview-date", with: (release_date2 + 1.minute)
        click_on I18n.t("cms.preview_page")
      end
      wait_for_js_ready

      expect(page).to have_link(item1.name)
      expect(page).to have_link(item2.name)
      expect(page).to have_link(item3.name)
    end
  end
end
