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

      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_index'))

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[poster]", with: "sample"
        fill_in "item[text]", with: "sample"
        fill_in "item[delete_key]", with: "pass"
        click_button I18n.t('ss.buttons.save')
      end

      visit edit_path

      click_on I18n.t("ss.buttons.upload")

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.attach")
        wait_for_ajax
      end
      click_button I18n.t('ss.buttons.save')

      expect(page).to have_text('keyvisual.jpg')

      visit logs_path
      expect(page).to have_css('.list-item', count: 4)
    end
  end
end
