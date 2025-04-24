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
        auto_description = item.description

        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_manual"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.description_setting).to eq 'manual'
        expect(item.description).to eq auto_description
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

    context "when duplicating a page" do
      let(:original_html) { "<p>Original content for testing duplication.</p>" }
      let(:updated_html) { "<p>Updated content after duplication.</p>" }
      let(:item) { create(:cms_page, site: site, html: original_html) }

      it "updates description when html is changed in duplicated page with auto mode" do
        # オリジナルページを作成
        visit edit_cms_page_path(site.id, item)

        within "form#item-form" do
          fill_in "item[name]", with: "original"
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        original_item = Cms::Page.last

        # 複製
        visit cms_page_path(site.id, original_item)
        click_on I18n.t('ss.links.copy')
        within "form#item-form" do
          fill_in "item[name]", with: "duplicate"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        duplicated_item = Cms::Page.last
        expect(duplicated_item.name).to eq "duplicate"
        expect(duplicated_item.description_setting).to eq 'auto'
        expect(duplicated_item.description).to eq 'Original content for testing duplication.'

        # 複製したページを編集
        visit edit_cms_page_path(site.id, duplicated_item)
        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: updated_html
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        duplicated_item.reload

        expect(duplicated_item.description).to eq 'Updated content after duplication.'
      end
    end

    context "when using replace page feature" do
      let(:original_html) { "<p>Original content of the published page.</p>" }
      let(:updated_html) { "<p>Updated content for the replacement page.</p>" }
      let(:item) { create(:cms_page, site: site, html: original_html) }
      it "updates description in the replacement page with auto mode" do
        # 公開ページを編集
        visit edit_cms_page_path(site.id, item)

        within "form#item-form" do
          fill_in "item[name]", with: "published"
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        published_item = Cms::Page.last

        # 差し替えページを作成
        visit cms_page_path(site.id, published_item)
        within "#addon-workflow-agents-addons-branch" do
          click_on I18n.t('workflow.create_branch')
          expect(page).to have_content('published')
          click_on 'published'
        end

        click_on I18n.t('ss.links.edit')
        within "form#item-form" do
          fill_in "item[name]", with: "replacement"
          fill_in_ckeditor "item[html]", with: updated_html
          click_button I18n.t('ss.buttons.publish')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        replacement_item = Cms::Page.last

        expect(replacement_item.name).to eq "replacement"
        expect(replacement_item.description_setting).to eq 'auto'
        expect(replacement_item.description).to eq 'Updated content for the replacement page.'

        # 公開後、元のページは置き換えられるが、内容自体は新しい内容に変わっているはず
        published_item.reload

        expect(published_item.html).to include updated_html
        expect(published_item.description).to eq 'Updated content for the replacement page.'
      end
    end
  end
end
