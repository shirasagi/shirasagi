require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
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

  context "https://github.com/shirasagi/shirasagi/issues/4543" do
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
  end

  context "when draft_save is clicked" do
    it do
      visit article_pages_path(site: site, cid: node)
      click_on page2.name
      click_on I18n.t("ss.buttons.edit")

      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html

        click_on I18n.t("ss.buttons.withdraw")
      end

      within "#cboxLoadedContent" do
        expect(page).to have_css("li", text: I18n.t('ss.confirm.contains_url_expect'))
        expect(page).to have_no_css('.save')
      end
    end
  end

  context "with order_of_h checker error" do
    let(:html) { "<h6>#{unique_id}</h6>" }

    it do
      visit article_pages_path(site: site, cid: node)
      click_on page1.name
      click_on I18n.t("ss.buttons.edit")

      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html

        click_on I18n.t("ss.buttons.withdraw")
      end

      within "#cboxLoadedContent" do
        expect(page).to have_css("li", text: I18n.t('errors.messages.invalid_order_of_h'))
        expect(page).to have_css("li", text: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
        expect(page).to have_css('.save')
      end
    end
  end

  context "with embedded_media checker error" do
    let(:html) { '<embed type="video/webm" src="/fs/1/1/1/_/video.mp4">' }

    it do
      visit article_pages_path(site: site, cid: node)
      click_on page1.name
      click_on I18n.t("ss.buttons.edit")

      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html

        click_on I18n.t("ss.buttons.withdraw")
      end

      within "#cboxLoadedContent" do
        expect(page).to have_css("li", text: I18n.t('errors.messages.check_embedded_media'))
        expect(page).to have_no_css("li", text: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
        expect(page).to have_css('.save')
      end
    end
  end

  context "with order_of_h checker error and embedded_media checker error" do
    let(:html) { "<h6>#{unique_id}</h6>" + '<embed type="video/webm" src="/fs/1/1/1/_/video.mp4">' }

    it do
      visit article_pages_path(site: site, cid: node)
      click_on page1.name
      click_on I18n.t("ss.buttons.edit")

      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html

        click_on I18n.t("ss.buttons.withdraw")
      end

      within "#cboxLoadedContent" do
        expect(page).to have_css("li", text: I18n.t('errors.messages.invalid_order_of_h'))
        expect(page).to have_css("li", text: I18n.t('errors.messages.check_embedded_media'))
        expect(page).to have_css("li", text: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
        expect(page).to have_css('.save')
      end
    end
  end
end
