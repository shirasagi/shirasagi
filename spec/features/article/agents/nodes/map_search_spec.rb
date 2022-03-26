require 'spec_helper'

describe "article_agents_nodes_map_search", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_map_search, layout_id: layout.id, filename: "node", form_id: form }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'entry') }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".map-search-settings")

      click_button I18n.t('facility.submit.reset')
      click_button I18n.t('facility.submit.search')
      expect(page).to have_css(".map-search-result")

      find('.map-search-tabs').click
      expect(page).to have_css(".map-search-result")
    end
  end
end
