require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let!(:site){ cms_site }
  let!(:user){ cms_user }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:item) { create :article_page, cur_user: user, cur_site: site, cur_node: node, state: "closed" }
  let(:logo_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  before do
    @save_file_upload_dialog = SS.file_upload_dialog
    SS.file_upload_dialog = :v2
  end

  after do
    SS.file_upload_dialog = @save_file_upload_dialog
  end

  context "when a <img> element is dropped into CKEditor" do
    it do
      login_user user, to: edit_article_page_path(site: site, cid: node, id: item)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "form#item-form" do
        ss_upload_file logo_path
        within "#addon-cms-agents-addons-file" do
          expect(page).to have_css(".file-view", count: 1)
        end
      end

      # drop <img> element into CKEditor
      # see: https://github.com/SeleniumHQ/selenium/blob/trunk/rb/lib/selenium/webdriver/common/interactions/pointer_actions.rb
      logo_file = SS::File.find_by(name: File.basename(logo_path))
      logo_image_el = page.first(".file-view[data-file-id='#{logo_file.id}'] img")
      ckeditor_el = page.first("#cke_item_html")
      page.driver.browser.action.tap do |action_builder|
        action_builder
          .drag_and_drop(logo_image_el.native, ckeditor_el.native)
          .perform
      end

      sleep 0.1
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      click_on I18n.t("ss.buttons.ignore_alert")
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      item.reload
      Nokogiri::HTML.fragment(item.html).tap do |html|
        expect(html.css("img")).to have(0).items
      end
    end
  end
end
