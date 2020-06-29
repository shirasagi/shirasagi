require 'spec_helper'

describe "urgency_layouts", type: :feature, dbscope: :example do
  let!(:site) { cms_site }

  let!(:node) { create :urgency_node_layout, filename: "urgency", urgency_default_layout_id: layout1.id }
  let!(:layout1) { create :cms_layout, cur_site: site, name: unique_id, filename: "layout1.layout.html" }
  let!(:layout2) { create :cms_layout, cur_site: site, name: unique_id, filename: "urgency/layout2.layout.html" }

  let!(:item) { create :cms_page, name: "index", filename: "index.html" }

  describe "apply urgency layout and vice versa" do
    before { login_cms_user }

    it do
      visit urgency_layouts_path(site: site, cid: node)

      click_on layout2.name
      click_on I18n.t('urgency.switch_layout')
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item.reload
      expect(item.layout_id).to eq layout2.id

      click_on layout1.name
      click_on I18n.t('urgency.switch_layout')
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item.reload
      expect(item.layout_id).to eq layout1.id
    end
  end

  describe "ss-3647" do
    before { login_cms_user }

    it do
      # change to urgency layout
      visit urgency_layouts_path(site: site, cid: node)
      click_on layout2.name
      click_on I18n.t('urgency.switch_layout')
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item.reload
      expect(item.layout_id).to eq layout2.id

      # edit page without any modifications
      visit cms_page_path(site: site, id: item)
      click_on I18n.t("ss.links.edit")
      click_on I18n.t("ss.buttons.save")
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      # confirm that layout is still set
      item.reload
      expect(item.layout_id).to eq layout2.id
    end
  end
end
