require 'spec_helper'

describe 'article_agents_nodes_page', dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:article_node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
  let!(:article_page) { create(:article_page, cur_site: site, cur_node: article_node, layout_id: layout.id) }
  let!(:login_node) { create(:member_node_login, cur_site: site, layout_id: layout.id) }

  feature do
    before do
      article_node.for_member_state = 'enabled'
      article_node.save!
    end

    it do
      # expected to be redirected to login
      visit article_node.full_url
      expect(page).to have_css('.member-login-box')

      # expected to be redirected to login
      visit article_page.full_url
      expect(page).to have_css('.member-login-box')
    end
  end
end
