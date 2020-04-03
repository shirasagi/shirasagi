require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node_node, filename: "node" }
  let!(:item) { create :cms_page, cur_node: node, basename: 'page' }

  context "with descendant page" do
    before { login_cms_user }

    it "#index" do
      visit cms_pages_path(site: site.id)
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_selector('li.list-item', count: 0)

      select I18n.t('cms.options.node_target.descendant'), from: 's[target]'
      click_on I18n.t('ss.buttons.search')
      expect(page).to have_selector('li.list-item', count: 1)

      click_link item.name
      expect(current_path).to eq node_page_path(site: site.id, cid: node.id, id: item.id)
    end
  end
end
