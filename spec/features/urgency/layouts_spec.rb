require 'spec_helper'

describe "urgency_layouts", type: :feature, dbscope: :example do
  let!(:site) { cms_site }

  let!(:node) { create_once :urgency_node_layout, filename: "urgency", urgency_default_layout_id: layout1.id }
  let!(:layout1) { create :cms_layout, cur_site: site, name: unique_id, filename: "layout1.layout.html" }
  let!(:layout2) { create :cms_layout, cur_site: site, name: unique_id, filename: "urgency/layout2.layout.html" }

  let!(:item) { create_once :cms_page, name: "index", filename: "index.html" }
  let!(:index_path) { urgency_layouts_path site.id, node }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_on layout2.name
      click_on I18n.t('urgency.switch_layout')
      expect(current_path).to eq index_path
      expect(Cms::Page.find(item.id).layout_id).to eq layout2.id

      click_on layout1.name
      click_on I18n.t('urgency.switch_layout')
      expect(current_path).to eq index_path
      expect(Cms::Page.find(item.id).layout_id).to eq layout1.id
    end
  end
end
