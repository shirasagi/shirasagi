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
        find_by_id('addon-cms-agents-addons-meta').click
        choose "item_description_setting_auto"
        click_button I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item = Cms::Page.last
      expect(item.name).to eq "sample"
      expect(item.filename).to eq "sample.html"
      expect(item.keywords).to eq [site.name]
      expect(item.description_setting).to eq 'auto'
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
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          find_by_id('addon-category-agents-addons-category').click
          check category.name
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item = Cms::Page.last
        expect(item.name).to eq "sample"
        expect(item.filename).to eq "#{node.filename}/sample.html"
        expect(item.keywords).to eq [node.name, category.name]
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to eq 'sample'
        expect(item.summary).to eq 'sample'
      end
    end
  end

  describe "meta description settings" do
    let(:html_content) { "<p>This is a test content for description. It should be automatically set as description.</p>" }
    let(:manual_description) { "This is a manually set description." }

    before do
      site.set(auto_keywords: 'enabled', auto_description: 'enabled')
      login_cms_user
    end

    context "when creating new page" do
      it "automatically sets description in auto mode" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in "item[basename]", with: "sample"
          fill_in_ckeditor "item[html]", with: html_content
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item = Cms::Page.last
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to eq 'This is a test content for description. It should be auto...'
      end

      it "keeps manual description in manual mode" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in "item[basename]", with: "sample"
          fill_in_ckeditor "item[html]", with: html_content
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_manual"
          fill_in "item[description]", with: manual_description
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item = Cms::Page.last
        expect(item.description_setting).to eq 'manual'
        expect(item.description).to eq manual_description
      end
    end

    context "when editing existing page" do
      let(:item) { create(:cms_page, site: site, html: html_content) }

      it "updates description when switching to auto mode" do
        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to eq 'This is a test content for description. It should be auto...'
      end

      it "keeps existing description when switching to manual mode" do
        # 最初に自動モードで保存
        item.update!(description_setting: 'auto')

        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          find_by_id('addon-cms-agents-addons-meta').click
          accept_confirm(I18n.t('cms.confirm.change_to_manual')) do
            choose "item_description_setting_manual"
          end
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.description_setting).to eq 'manual'
        expect(item.description).to be_blank # 手動モードに切り替えた時は説明文がクリアされる
      end

      it "updates description when html is changed in auto mode" do
        item.update!(description_setting: 'auto')
        new_html = "<p>Updated content for testing auto description update.</p>"

        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          find_by_id('addon-cms-agents-addons-meta').click
          fill_in_ckeditor "item[html]", with: new_html
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item.reload
        expect(item.description).to eq 'Updated content for testing auto description update.'
      end
    end
  end
end
