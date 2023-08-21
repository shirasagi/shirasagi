require 'spec_helper'

describe "board_posts", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :board_node_post, filename: "posts", name: "posts" }
  let(:item) { create(:board_post, node: node) }
  let(:index_path) { board_posts_path site.id, node }
  let(:new_path) { new_board_post_path site.id, node }
  let(:show_path) { board_post_path site.id, node, item }
  let(:edit_path) { edit_board_post_path site.id, node, item }
  let(:delete_path) { delete_board_post_path site.id, node, item }
  let(:reply) { create(:board_post, node: node, topic: item.id, parent_id: item.id) }
  let(:new_reply_path) { new_reply_board_post_path site.id, node, item }
  let(:edit_reply_path) { edit_board_post_path site.id, node, reply }
  let(:reply_show_path) { board_post_path site.id, node, reply }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.new'))
      expect(page).to have_css('div#menu nav a', text: 'ダウンロード')
    end

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
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.edit'))
      expect(page).to have_css('div#menu nav a', text: '返信する')
      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.delete'))
      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_index'))
    end

    it "#edit" do
      visit edit_path

      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_show'))
      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_index'))

      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path

      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_show'))
      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_index'))

      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "#new_reply" do
      visit new_reply_path

      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_index'))

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[poster]", with: "sample"
        fill_in "item[text]", with: "sample"
        fill_in "item[poster_url]", with: "https://www.web-tips.co.jp/"
        fill_in "item[delete_key]", with: "pass"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_reply_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#edit_reply" do
      visit edit_reply_path

      expect(page).to have_css('div#menu nav a', text: I18n.t('ss.links.back_to_index'))

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[poster]", with: "sample"
        fill_in "item[text]", with: "sample"
        fill_in "item[poster_url]", with: "https://www.web-tips.co.jp/"
        fill_in "item[delete_key]", with: "pass"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq edit_reply_path
      expect(page).to have_no_css("form#item-forms")
      expect(reply.topic_id).to eq item.id
      expect(reply.parent_id).to eq item.id
    end
  end
end
