require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:folder1) { create :gws_notice_folder, cur_site: site }
  let!(:folder2) { create :gws_notice_folder, cur_site: site }
  let!(:post) { create :gws_notice_post, cur_site: site, folder: folder1 }

  context "move notice" do
    it do
      login_gws_user to: gws_notice_main_path(site: site)
      wait_for_all_turbo_frames
      click_on I18n.t('ss.navi.editable')
      wait_for_all_turbo_frames
      expect(page).to have_css('.gws-notice-folder_tree', text: folder1.name)
      expect(page).to have_css('.gws-notice-folder_tree', text: folder2.name)
      expect(page).to have_css('.list-items', text: post.name)
      within '.list-items' do
        click_on post.name
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.move")
      end
      within 'form#item-form' do
        open_dialog I18n.t('gws/share.apis.folders.index')
      end
      within_cbox do
        expect(page).to have_css(".list-item[data-id='#{folder2.id}']", text: folder2.name)
        expect(page).to have_no_css(".list-item[data-id='#{folder1.id}']")

        within ".search" do
          fill_in "s[keyword]", with: folder2.name
          click_on I18n.t("ss.buttons.search")
        end
      end
      within_cbox do
        expect(page).to have_css(".list-item[data-id='#{folder2.id}']", text: folder2.name)
        expect(page).to have_no_css(".list-item[data-id='#{folder1.id}']")

        wait_for_cbox_closed { click_on folder2.name }
      end
      within 'form#item-form' do
        expect(page).to have_css("#addon-basic .ajax-selected [data-id='#{folder2.id}']", text: folder2.name)
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Gws::Notice::Post.find(post.id).tap do |post_after_move|
        expect(post_after_move.site_id).to eq post.site_id
        expect(post_after_move.name).to eq post.name
        expect(post_after_move.folder_id).to eq folder2.id
        expect(post_after_move.state).to eq post.state
      end
    end
  end
end
