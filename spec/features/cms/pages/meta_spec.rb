require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  subject(:index_path) { cms_pages_path site.id }

  describe "basic crud" do
    before do
      site.set(auto_keywords: 'enabled', auto_description: 'enabled')
      login_cms_user
    end

    it do
      visit new_cms_page_path(site.id)
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        fill_in_ckeditor "item[html]", with: "<p>sample</p>"
        click_button I18n.t('ss.buttons.publish_save')
      end

      item = Cms::Page.last
      expect(item.name).to eq "sample"
      expect(item.filename).to eq "sample.html"
      expect(item.keywords).to eq [site.name]
      expect(item.description).to eq 'sample'
      expect(item.summary).to eq 'sample'
    end

    context 'with node' do
      let(:node) { create_once :cms_node_page }
      let!(:category) { create_once :category_node_page }

      it do
        visit new_node_page_path(site.id, node.id)
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in "item[basename]", with: "sample"
          fill_in_ckeditor "item[html]", with: "<p>sample</p>"
          find_by_id('addon-category-agents-addons-category').click
          check category.name
          click_button I18n.t('ss.buttons.publish_save')
        end

        item = Cms::Page.last
        expect(item.name).to eq "sample"
        expect(item.filename).to eq "#{node.filename}/sample.html"
        expect(item.keywords).to eq [node.name, category.name]
        expect(item.description).to eq 'sample'
        expect(item.summary).to eq 'sample'
      end
    end
  end
end
