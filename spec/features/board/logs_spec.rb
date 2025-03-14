require 'spec_helper'

describe "board_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :board_node_post, filename: "posts", name: "posts" }
  let(:item) { create(:board_post, node: node) }
  let(:index_path) { board_posts_path site.id, node }
  let(:new_path) { new_board_post_path site.id, node }
  let(:show_path) { board_post_path site.id, node, item }
  let(:edit_path) { edit_board_post_path site.id, node, item }
  let(:delete_path) { delete_board_post_path site.id, node, item }
  subject(:logs_path) { history_cms_logs_path site.id }

  context "history_logs" do
    before { login_cms_user }

    it "#new" do
      visit new_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_index'))

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[poster]", with: "sample"
        fill_in "item[text]", with: "sample"
        fill_in "item[delete_key]", with: "pass"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      visit edit_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        ss_upload_file "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg", addon: "#addon-board-agents-addons-file"
        expect(page).to have_css("#addon-board-agents-addons-file .file-view", text: "keyvisual.jpg")
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_text('keyvisual.jpg')

      visit logs_path
      expect(page).to have_css('.list-item', count: 4)
    end
  end
end
