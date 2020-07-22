require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create(:article_node_page, filename: "docs", name: "article") }
  let!(:item) { create(:article_page, cur_node: node) }
  let(:new_path) { new_article_page_path site.id, node }

  context "with related page in body" do
    before { login_cms_user }

    it "#new" do
      visit new_path

      within '#addon-cms-agents-addons-body' do
        click_link I18n.t('cms.apis.related_pages.index')
      end

      wait_for_cbox do
        click_link item.name
      end

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_button I18n.t('ss.buttons.publish_save')
      end

      Article::Page.where(name: 'sample').first.tap do |article_page|
        expect(article_page.html).to include(item.url)
      end
    end

    context 'with subdir site' do
      let(:site2) { create(:cms_site, host: unique_id, domains: [unique_id]) }
      let(:node) { create(:article_node_page, filename: "docs", name: "article") }
      let!(:item) { create(:article_page, cur_node: node) }
      let(:new_path) { new_article_page_path site.id, node }

      before do
        site.domains = site2.domains
        site.subdir = unique_id
        site.save!
        item.reload
      end

      it "#new" do
        visit new_path

        within '#addon-cms-agents-addons-body' do
          click_link I18n.t('cms.apis.related_pages.index')
        end

        wait_for_cbox do
          click_link item.name
        end

        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          click_button I18n.t('ss.buttons.publish_save')
        end

        Article::Page.where(name: 'sample').first.tap do |article_page|
          expect(article_page.html).to include(item.url)
        end
      end
    end
  end
end
