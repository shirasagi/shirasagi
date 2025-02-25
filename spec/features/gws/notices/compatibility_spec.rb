require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let(:v170_item) { create :gws_notice_post, folder: folder }

  context 'when v1.7.0 post is given' do
    V170_FIELDS = %w(
      _id close_date created custom_group_ids custom_groups_hash deleted email_notification group_ids
      groups_hash message_notification name notification_noticed readable_custom_group_ids
      readable_custom_groups_hash readable_group_ids readable_groups_hash readable_member_ids
      readable_members_hash readable_setting_range release_date released severity site_id state text
      text_index text_type updated user_group_id user_group_name user_id user_ids user_name user_uid users_hash
    ).freeze

    before do
      unset_fields = v170_item.fields.keys - V170_FIELDS
      v170_item.unset(*unset_fields)
      v170_item.reload
      unset_fields.sample(3).each do |f|
        expect(v170_item[f].presence).to be_nil
      end

      login_gws_user
    end

    it do
      # portal
      visit gws_portal_path(site: site)
      expect(page).to have_css('.list-items', text: v170_item.name)
      first('.list-items .title a', text: v170_item.name).click
      expect(page).to have_content(v170_item.name)

      # readable list
      visit gws_notice_main_path(site: site)
      expect(page).to have_css('.tree-navi', text: folder.name)
      expect(page).to have_css('.list-items', text: v170_item.name)
      within '.list-items' do
        click_on v170_item.name
      end
      expect(page).to have_content(v170_item.name)

      # editable list
      visit gws_notice_main_path(site: site)
      click_on I18n.t('ss.navi.editable')
      expect(page).to have_css('.tree-navi', text: folder.name)
      expect(page).to have_css('.list-items', text: v170_item.name)
      within '.list-items' do
        click_on v170_item.name
      end
      expect(page).to have_content(v170_item.name)

      # move post to appropriate folder
      within ".nav-menu" do
        click_on I18n.t("ss.links.move")
      end
      within 'form#item-form' do
        open_dialog I18n.t('gws/share.apis.folders.index')
      end
      within_cbox do
        expect(page).to have_content(folder.name)
        wait_for_cbox_closed { click_on folder.name }
      end
      within 'form#item-form' do
        expect(page).to have_css("#addon-basic .ajax-selected [data-id='#{folder.id}']", text: folder.name)
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # check post
      visit gws_notice_main_path(site: site)
      expect(page).to have_css('.tree-navi', text: folder.name)
      first('.tree-navi', text: folder.name).click
      expect(page).to have_css('.tree-navi', text: folder.name)
      expect(page).to have_css('.list-items', text: v170_item.name)
    end
  end
end
