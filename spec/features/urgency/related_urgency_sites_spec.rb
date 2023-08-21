require 'spec_helper'

describe "urgency_layouts", type: :feature, dbscope: :example, js: true do
  let!(:site1) { cms_site }
  let!(:site2) { create :cms_site_unique }
  let!(:site3) { create :cms_site_unique }

  let!(:node1) do
    create(:urgency_node_layout, cur_site: site1,
      filename: "urgency", urgency_default_layout_id: layout1.id,
      related_urgency_site_ids: [site1.id, site2.id])
  end
  let!(:node2) do
    create(:urgency_node_layout, cur_site: site2,
      filename: "urgency", urgency_default_layout_id: layout2.id)
  end
  let!(:node3) do
    create(:urgency_node_layout, cur_site: site3,
      filename: "urgency", urgency_default_layout_id: layout3.id)
  end

  let!(:layout1) { create :cms_layout, cur_site: site1, filename: "layout1.layout.html" }
  let!(:layout2) { create :cms_layout, cur_site: site2, filename: "layout1.layout.html" }
  let!(:layout3) { create :cms_layout, cur_site: site3, filename: "layout1.layout.html" }

  let!(:layout4) { create :cms_layout, cur_site: site1, filename: "urgency/layout2.layout.html" }
  let!(:layout5) { create :cms_layout, cur_site: site2, filename: "urgency/layout2.layout.html" }
  let!(:layout6) { create :cms_layout, cur_site: site3, filename: "urgency/layout2.layout.html" }

  let!(:item1) { create :cms_page, cur_site: site1, name: "index", layout_id: layout1.id, filename: "index.html" }
  let!(:item2) { create :cms_page, cur_site: site2, name: "index", layout_id: layout2.id, filename: "index.html" }
  let!(:item3) { create :cms_page, cur_site: site3, name: "index", layout_id: layout3.id, filename: "index.html" }

  describe "apply urgency layout and vice versa" do
    before { login_cms_user }

    it do
      visit urgency_layouts_path(site: site1, cid: node1)
      click_on layout4.name
      page.accept_alert do
        click_on I18n.t('urgency.switch_layout')
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item1.reload
      item2.reload
      item3.reload
      expect(item1.layout_id).to eq layout4.id
      expect(item2.layout_id).to eq layout5.id
      expect(item3.layout_id).to eq layout3.id

      visit urgency_layouts_path(site: site1, cid: node1)
      click_on layout1.name
      page.accept_alert do
        click_on I18n.t('urgency.switch_layout')
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item1.reload
      item2.reload
      item3.reload
      expect(item1.layout_id).to eq layout1.id
      expect(item2.layout_id).to eq layout2.id
      expect(item3.layout_id).to eq layout3.id
    end
  end
end
