require 'spec_helper'

describe "aute_save", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:group) { cms_group }
  let(:item) { create(:article_page, cur_node: node) }

  let(:article_index_path) { article_pages_path site.id, node }
  let(:article_new_path) { new_article_page_path site.id, node }
  let(:article_edit_path) { edit_article_page_path site.id, node, item }
  let(:article_show_path) { article_page_path site.id, node, item }

  let(:page_index_path) { cms_pages_path site.id }
  let(:page_new_path) { new_cms_page_path site.id }
  let(:page_edit_path) { edit_cms_page_path site.id, item }
  let(:page_show_path) { cms_page_path site.id, item }

  let(:node_node) { create(:cms_node_page, filename: "docs", name: "node", group_ids: [group.id]) }
  let(:node_item) { create :cms_page, cur_node: node_node, state: "closed", group_ids: [group.id] }
  let(:node_index_path) { node_pages_path site.id, node_node }
  let(:node_new_path) { new_node_page_path site.id, node_node }
  let(:node_edit_path) { edit_node_page_path site.id, node_node, node_item }
  let(:node_show_path) { node_page_path site.id, node_node, node_item }

  let(:event_node) { create(:event_node_page, group_ids: [group.id]) }
  let(:event_item) { create(:event_page, cur_node: event_node) }
  let(:event_index_path) { event_pages_path site.id, event_node }
  let(:event_new_path) { new_event_page_path site.id, event_node }
  let(:event_edit_path) { edit_event_page_path site.id, event_node, event_item }
  let(:event_show_path) { event_page_path site.id, event_node, event_item }

  let(:faq_node) { create(:faq_node_page, group_ids: [group.id]) }
  let(:faq_item) { create(:faq_page, cur_node: faq_node) }
  let(:faq_index_path) { faq_pages_path site.id, faq_node }
  let(:faq_new_path) { new_faq_page_path site.id, faq_node }
  let(:faq_edit_path) { edit_faq_page_path site.id, faq_node, faq_item }
  let(:faq_show_path) { faq_page_path site.id, faq_node, faq_item }

  before { login_cms_user }

  context "記事ページ" do
    it "new" do
      visit article_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      click_on I18n.t("ss.links.back_to_index")

      visit article_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("sample")
    end

    it "edit" do
      visit article_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
      end
      click_on I18n.t("ss.links.back_to_show")
      wait_for_js_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      visit article_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
    end
  end

  context "固定ページ(フォルダー直下)" do
    it "new" do
      visit page_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
      end
      click_on I18n.t("ss.links.back_to_index")

      visit page_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("sample")
    end

    it "edit" do
      visit page_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
      end
      click_on I18n.t("ss.links.back_to_show")
      wait_for_js_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      visit page_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
    end
  end

  context "固定ページ(記事フォルダー配下)" do
    it "new" do
      visit node_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
      end
      click_on I18n.t("ss.links.back_to_index")

      visit node_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("sample")
    end

    it "edit" do
      visit node_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
      end
      click_on I18n.t("ss.links.back_to_show")
      wait_for_js_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      visit node_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
    end
  end

  context "FAQページ" do
    it "new" do
      visit faq_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      click_on I18n.t("ss.links.back_to_index")

      visit faq_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("sample")
    end

    it "edit" do
      visit faq_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
      end
      click_on I18n.t("ss.links.back_to_show")
      wait_for_js_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      visit faq_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
    end
  end

  context "イベントページ" do
    it "new" do
      visit event_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      click_on I18n.t("ss.links.back_to_index")

      visit event_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("sample")
    end

    it "edit" do
      visit event_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
      end
      click_on I18n.t("ss.links.back_to_show")
      wait_for_js_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      visit event_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
    end
  end
end