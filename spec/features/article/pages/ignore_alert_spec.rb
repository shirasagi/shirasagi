require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }

  context "https://github.com/shirasagi/shirasagi/issues/4543" do
    let!(:page1) { create :article_page, cur_site: site, cur_node: node, state: "public" }
    let!(:page2) { create :article_page, cur_site: site, cur_node: node, state: "public" }
    let(:html) { "<p>#{unique_id}</p>" }

    before do
      page1.related_page_ids = [ page2.id ]
      page1.save!
      page1.reload

      role = cms_role
      role.permissions = role.permissions - %w(edit_cms_ignore_alert edit_cms_ignore_syntax_check)
      role.save!

      login_cms_user
    end

    it do
      visit article_pages_path(site: site, cid: node)
      click_on page2.name
      click_on I18n.t("ss.buttons.edit")

      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      page2.reload
      expect(page2.html).to eq html
    end

    context "when draft_save is clicked" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        click_on I18n.t("ss.buttons.edit")

        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: html

          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end
        within_cbox do
          expect(page).to have_css("li", text: I18n.t('ss.confirm.contains_url_expect'))
          expect(page).to have_no_css('.save')
        end
      end
    end

    context "with syntax check error" do
      let(:html) { "<h6>#{unique_id}</h6>" }

      it do
        visit article_pages_path(site: site, cid: node)
        click_on page1.name
        click_on I18n.t("ss.buttons.edit")

        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: html

          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end
        within_cbox do
          expect(page).to have_css("li", text: I18n.t('errors.messages.invalid_order_of_h'))
          expect(page).to have_css("li", text: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
          expect(page).to have_no_css('.save')
        end
      end
    end
  end

  # 下書き → 下書きの場合、被リンクが存在していても保存可能
  context "https://github.com/shirasagi/shirasagi/issues/4431" do
    let!(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout: layout }
    let(:page_a) { create(:article_page, cur_site: site, cur_node: node, layout: layout, state: "closed") }
    let(:page_b) do
      html = <<~HTML
        <a href="#{page_a.url}">#{page_a.name}</a>
      HTML
      create(:article_page, cur_site: site, cur_node: node, layout: layout, html: html, state: "public")
    end

    before { login_cms_user }

    it do
      visit edit_article_page_path(site: site, cid: node, id: page_a)
      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: "<h4>Header 4</h4>"
        wait_for_cbox_opened { click_on I18n.t("ss.buttons.draft_save") }
      end
      within_cbox do
        expect(page).to have_css("li", text: I18n.t('errors.messages.invalid_order_of_h'))
        click_on I18n.t("ss.buttons.ignore_alert")
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end
  end
end
