require 'spec_helper'

describe "michecker", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create(:article_node_page, filename: "docs", name: "article") }
  let(:item) { create(:article_page, cur_node: node) }
  let(:show_path) { article_page_path site.id, node, item }

  context "route check" do
    before { login_cms_user }

    it do
      visit show_path
      expect(page).to have_content(I18n.t('cms.links.michecker'))
      click_on I18n.t('cms.links.michecker')
      expect(page).to have_text I18n.t('cms.cms/michecker.start')
    end
  end
end
