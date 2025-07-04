require 'spec_helper'
require 'nokogiri'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  subject(:index_path) { cms_pages_path site.id }
  let!(:layout) { create(:cms_layout_with_meta, site: site) }

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
      item.update!(layout_id: layout.id)

      expect(item.name).to eq "sample"
      expect(item.filename).to eq "sample.html"
      expect(item.keywords).to eq [site.name]
      expect(item.description_setting).to eq 'auto'
      expect(item.description).to eq 'sample'
      expect(item.summary).to eq 'sample'
      expect(item.layout_id).to eq layout.id

      # メタタグが生成されていることを確認
      url = File.read(item.path)
      doc = Nokogiri::HTML.parse(url)
      description_elements = doc.css("meta[name='description']")
      expect(description_elements).not_to be_empty
      expect(description_elements[0]['content']).to eq 'sample'
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
        item.update!(layout_id: layout.id)

        expect(item.name).to eq "sample"
        expect(item.filename).to eq "#{node.filename}/sample.html"
        expect(item.keywords).to eq [node.name, category.name]
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to eq 'sample'
        expect(item.summary).to eq 'sample'
        expect(item.layout_id).to eq layout.id

        # メタタグが生成されていることを確認
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq 'sample'
      end
    end
  end

  describe "meta description settings" do
    let(:html_content) { "<p>This is a test content for description. It should be automatically set as description.</p>" }
    let(:manual_description) { "This is a manually set description." }
    let(:auto_generated_description) { "This is a test content for description. It should be auto..." }

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
        item.update!(layout_id: layout.id)

        expect(item.description_setting).to eq 'auto'
        expect(item.description).to eq auto_generated_description
        expect(item.layout_id).to eq layout.id

        # メタタグが生成されていることを確認
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to match(auto_generated_description)
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
        item.update!(layout_id: layout.id)

        expect(item.description_setting).to eq 'manual'
        expect(item.description).to eq manual_description
        expect(item.layout_id).to eq layout.id

        # メタタグが生成されていることを確認
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq manual_description
      end
    end

    context "when editing existing page" do
      let(:item) { create(:cms_page, site: site, html: html_content, layout_id: layout.id) }

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
        expect(item.description).to eq auto_generated_description

        # メタタグが生成されていることを確認
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to match(auto_generated_description)
      end

      it "updates description when html is changed in auto mode" do
        item.update!(description_setting: 'auto')
        updated_html = "<p>Updated content for testing auto description update.</p>"
        updated_description = 'Updated content for testing auto description update.'

        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          find_by_id('addon-cms-agents-addons-meta').click
          fill_in_ckeditor "item[html]", with: updated_html
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item.reload
        expect(item.description).to eq updated_description

        # メタタグが生成されていることを確認
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq updated_description
      end
    end

    context "when duplicating a page" do
      let(:original_html) { "<p>Original content for testing duplication.</p>" }
      let(:updated_html) { "<p>Updated content after duplication.</p>" }
      let(:item) { create(:cms_page, site: site, html: original_html, layout_id: layout.id) }
      let(:original_description) { 'Original content for testing duplication.' }
      let(:updated_description) { 'Updated content after duplication.' }

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
        expect(original_item.name).to eq 'original'
        expect(original_item.description_setting).to eq 'auto'
        expect(original_item.description).to eq original_description

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
        expect(duplicated_item.description).to eq original_description

        # 複製したページを編集
        visit edit_cms_page_path(site.id, duplicated_item)
        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: updated_html
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # 複製したページの概要を確認
        duplicated_item.reload

        expect(duplicated_item.description).to eq updated_description

        # メタタグが生成されていることを確認
        url = File.read(duplicated_item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq updated_description

        # オリジナルページを確認
        original_item.reload

        expect(original_item.name).to eq 'original'
        expect(original_item.description_setting).to eq 'auto'
        expect(original_item.description).to eq original_description

        # メタタグが生成されていることを確認
        url = File.read(original_item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq original_description
      end
    end

    context "when using replace page feature" do
      let(:original_html) { "<p>Original content of the published page.</p>" }
      let(:updated_html) { "<p>Updated content for the replacement page.</p>" }
      let(:item) { create(:cms_page, site: site, html: original_html, layout_id: layout.id) }
      let(:original_description) { 'Original content of the published page.' }
      let(:updated_description) { 'Updated content for the replacement page.' }

      it "updates description in the replacement page with auto mode" do
        # 差し替え前のページを作成
        visit edit_cms_page_path(site.id, item)

        within "form#item-form" do
          fill_in "item[name]", with: "published"
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        published_item = Cms::Page.last
        expect(published_item.name).to eq 'published'
        expect(published_item.description_setting).to eq 'auto'
        expect(published_item.description).to eq original_description

        # 差し替えページを作成
        visit cms_page_path(site.id, published_item)
        within "#addon-workflow-agents-addons-branch" do
          click_on I18n.t('workflow.create_branch')
          expect(page).to have_content(published_item.name)
          click_on published_item.name
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
        expect(replacement_item.description).to eq updated_description

        # 公開後、元のページは置き換えられるが、内容自体は新しい内容に変わっているはず
        published_item.reload

        expect(published_item.html).to include updated_html
        expect(published_item.description).to eq updated_description

        # 公開されたページのメタタグを確認
        url = File.read(published_item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq updated_description
      end
    end

    # サイト設定で自動設定が無効な場合
    context "when auto_description is disabled" do
      let(:original_html) { "<p>Original content of the published page.</p>" }
      let(:original_description) { 'Original content of the published page.' }
      let(:item) { create(:cms_page, site: site, html: original_html, layout_id: layout.id) }

      before do
        site.set(auto_keywords: 'enabled', auto_description: 'disabled')
        expect(site.auto_description).to eq 'disabled'
      end

      it "sets description automatically from body as initial value" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in "item[basename]", with: "sample"
          fill_in_ckeditor "item[html]", with: html_content
          find_by_id('addon-cms-agents-addons-meta').click
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item = Cms::Page.last
        item.update!(layout_id: layout.id)

        expect(item.description_setting).to eq 'auto'
        expect(item.description).to be_blank
        expect(item.layout_id).to eq layout.id

        # メタタグが生成されていることを確認
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq auto_generated_description
      end

      it "updates description when body is updated after save" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "sample2"
          fill_in "item[basename]", with: "sample2"
          fill_in_ckeditor "item[html]", with: html_content
          find_by_id('addon-cms-agents-addons-meta').click
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item = Cms::Page.last
        item.update!(layout_id: layout.id)

        expect(item.description_setting).to eq 'auto'
        expect(item.description).to be_blank

        # 本文を更新
        updated_html = "<p>Updated content for testing auto description update (disabled mode).</p>"
        updated_description = "Updated content for testing auto description update (disa..."

        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: updated_html
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to be_blank

        # メタタグが更新されていることを確認
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq updated_description
      end

      it "manual mode: description is set and reflected in meta tag" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "manual"
          fill_in "item[basename]", with: "manual"
          fill_in_ckeditor "item[html]", with: "<p>Manual mode test</p>"
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_manual"
          fill_in "item[description]", with: "Manual description"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item = Cms::Page.last
        item.update!(layout_id: layout.id)
        expect(item.description_setting).to eq 'manual'
        expect(item.description).to eq "Manual description"
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq "Manual description"
      end

      it "auto mode: description is blank but meta tag is from body" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "auto"
          fill_in "item[basename]", with: "auto"
          fill_in_ckeditor "item[html]", with: "<p>Auto mode test</p>"
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item = Cms::Page.last
        item.update!(layout_id: layout.id)
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to be_blank
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq "Auto mode test"
      end

      it "switch manual→auto: description remains, meta tag from body" do
        # manualで作成
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "switch"
          fill_in "item[basename]", with: "switch"
          fill_in_ckeditor "item[html]", with: "<p>Switch test</p>"
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_manual"
          fill_in "item[description]", with: "Manual desc"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item = Cms::Page.last
        item.update!(layout_id: layout.id)
        # manual→autoに切り替え
        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item.reload
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to eq "Manual desc"
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq "Switch test"
      end

      it "auto mode: empty body results in empty meta tag" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "empty"
          fill_in "item[basename]", with: "empty"
          fill_in_ckeditor "item[html]", with: ""
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item = Cms::Page.last
        item.update!(layout_id: layout.id)
        expect(item.description_setting).to eq 'auto'
        expect(item.description).to be_blank
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq ""
      end

      it "auto mode: meta tag always reflects latest body" do
        visit new_cms_page_path(site.id)
        within "form#item-form" do
          fill_in "item[name]", with: "latest"
          fill_in "item[basename]", with: "latest"
          fill_in_ckeditor "item[html]", with: "<p>First body</p>"
          find_by_id('addon-cms-agents-addons-meta').click
          choose "item_description_setting_auto"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item = Cms::Page.last
        item.update!(layout_id: layout.id)
        # 1回目
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements[0]['content']).to eq "First body"
        # 2回目
        visit edit_cms_page_path(site.id, item)
        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: "<p>Second body</p>"
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        item.reload
        url = File.read(item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements[0]['content']).to eq "Second body"
      end

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
        expect(original_item.name).to eq 'original'
        expect(original_item.description_setting).to eq 'auto'
        expect(original_item.description).to be_blank

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
        expect(duplicated_item.description).to be_blank

        # 複製したページを編集
        visit edit_cms_page_path(site.id, duplicated_item)
        duplicated_html = "<p>Updated content for the duplicated page.</p>"
        duplicated_description = "Updated content for the duplicated page."
        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: duplicated_html
          click_button I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # 複製したページの概要を確認
        duplicated_item.reload

        expect(duplicated_item.description).to be_blank

        # メタタグが生成されていることを確認
        url = File.read(duplicated_item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq duplicated_description

        # オリジナルページを確認
        original_item.reload

        expect(original_item.name).to eq 'original'
        expect(original_item.description_setting).to eq 'auto'
        expect(original_item.description).to be_blank

        # メタタグが生成されていることを確認
        url = File.read(original_item.path)
        doc = Nokogiri::HTML.parse(url)
        description_elements = doc.css("meta[name='description']")
        expect(description_elements).not_to be_empty
        expect(description_elements[0]['content']).to eq original_description
      end

      # it "creates a branch (replacement) page and meta tag is from body" do
      #   let(:original_html) { "<p>Original content of the published page.</p>" }
      #   let(:original_description) { 'Original content of the published page.' }
      #   let(:item) { create(:cms_page, site: site, html: original_html, layout_id: layout.id) }
      #   let(:branch_html) { "<p>Branch page content</p>" }
      #   let(:branch_description) { 'Branch page content' }

      #   # 差し替え前ページ作成
      #   visit new_cms_page_path(site.id)
      #   within "form#item-form" do
      #     fill_in "item[name]", with: "branch"
      #     fill_in "item[basename]", with: "branch"
      #     fill_in_ckeditor "item[html]", with: original_html
      #     find_by_id('addon-cms-agents-addons-meta').click
      #     click_button I18n.t('ss.buttons.publish_save')
      #   end
      #   wait_for_notice I18n.t("ss.notice.saved")
      #   branch_item = Cms::Page.last
      #   branch_item.update!(layout_id: layout.id)

      #   expect(branch_item.description_setting).to eq 'auto'
      #   expect(branch_item.description).to be_blank

      #   url = File.read(branch_item.path)
      #   doc = Nokogiri::HTML.parse(url)
      #   description_elements = doc.css("meta[name='description']")
      #   expect(description_elements).not_to be_empty
      #   expect(description_elements[0]['content']).to eq branch_description
      # end

      # it "updates description in the replacement page with auto mode" do
      #   # 差し替え前のページを作成
      #   visit edit_cms_page_path(site.id, item)

      #   within "form#item-form" do
      #     fill_in "item[name]", with: "published"
      #     find_by_id('addon-cms-agents-addons-meta').click
      #     choose "item_description_setting_auto"
      #     click_button I18n.t('ss.buttons.publish_save')
      #   end
      #   wait_for_notice I18n.t("ss.notice.saved")

      #   published_item = Cms::Page.last
      #   expect(published_item.name).to eq 'published'
      #   expect(published_item.description_setting).to eq 'auto'
      #   expect(published_item.description).to eq original_description

      #   # 差し替えページを作成
      #   visit cms_page_path(site.id, published_item)
      #   within "#addon-workflow-agents-addons-branch" do
      #     click_on I18n.t('workflow.create_branch')
      #     expect(page).to have_content(published_item.name)
      #     click_on published_item.name
      #   end

      #   click_on I18n.t('ss.links.edit')
      #   within "form#item-form" do
      #     fill_in "item[name]", with: "replacement"
      #     fill_in_ckeditor "item[html]", with: updated_html
      #     click_button I18n.t('ss.buttons.publish')
      #   end
      #   wait_for_notice I18n.t("ss.notice.saved")

      #   replacement_item = Cms::Page.last

      #   expect(replacement_item.name).to eq "replacement"
      #   expect(replacement_item.description_setting).to eq 'auto'
      #   expect(replacement_item.description).to eq updated_description

      #   # 公開後、元のページは置き換えられるが、内容自体は新しい内容に変わっているはず
      #   published_item.reload

      #   expect(published_item.html).to include updated_html
      #   expect(published_item.description).to eq updated_description

      #   # 公開されたページのメタタグを確認
      #   url = File.read(published_item.path)
      #   doc = Nokogiri::HTML.parse(url)
      #   description_elements = doc.css("meta[name='description']")
      #   expect(description_elements).not_to be_empty
      #   expect(description_elements[0]['content']).to eq updated_description
      # end
    end
  end
end
