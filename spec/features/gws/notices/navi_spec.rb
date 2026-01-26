require 'spec_helper'

describe "gws_notice_folders", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:user) { create :gws_user, cur_site: site, group_ids: admin.group_ids }
  let!(:public_folder) do
    # admin から見ると管理可能だけど閲覧は不可なフォルダー
    create(
      :gws_notice_folder, cur_site: site, state: "public",
      member_custom_group_ids: [], member_group_ids: [], member_ids: [ admin.id ],
      readable_setting_range: "public", group_ids: admin.group_ids)
  end
  let!(:post_under_public) do
    create(
      :gws_notice_post, cur_site: site, folder: public_folder, state: "public",
      readable_setting_range: "public", group_ids: admin.group_ids)
  end
  let!(:limited_folder) do
    # admin から見ると管理可能だけど閲覧は不可なフォルダー
    create(
      :gws_notice_folder, cur_site: site, state: "public",
      member_custom_group_ids: [], member_group_ids: [], member_ids: [ admin.id ],
      readable_setting_range: "select", readable_custom_group_ids: [], readable_group_ids: [], readable_member_ids: [ user.id ],
      group_ids: admin.group_ids)
  end
  let!(:post_under_limited) do
    create(
      :gws_notice_post, cur_site: site, folder: limited_folder, state: "public",
      readable_setting_range: "select", readable_custom_group_ids: [], readable_group_ids: [], readable_member_ids: [ user.id ],
      group_ids: admin.group_ids)
  end

  it do
    # 閲覧一覧のトップ
    login_user admin, to: gws_notice_main_path(site: site)
    wait_for_all_turbo_frames
    within '.gws-notice-folder_tree' do
      expect(page).to have_css(".ss-tree-item[data-node-id='#{public_folder.id}']", text: public_folder.name)
      expect(page).to have_no_css('.ss-tree-item', text: limited_folder.name)
    end
    within '.list-items' do
      expect(page).to have_css(".list-item[data-id='#{post_under_public.id}']", text: post_under_public.name)
      expect(page).to have_no_css(".list-item[data-id='#{post_under_limited.id}']", text: post_under_limited.name)
    end

    # 管理一覧のトップ
    click_on I18n.t('ss.navi.editable')
    wait_for_all_turbo_frames
    within '.gws-notice-folder_tree' do
      expect(page).to have_css(".ss-tree-item[data-node-id='#{public_folder.id}']", text: public_folder.name)
      expect(page).to have_css(".ss-tree-item[data-node-id='#{limited_folder.id}']", text: limited_folder.name)
    end
    within '.list-items' do
      expect(page).to have_css(".list-item[data-id='#{post_under_public.id}']", text: post_under_public.name)
      expect(page).to have_css(".list-item[data-id='#{post_under_limited.id}']", text: post_under_limited.name)
    end

    # 管理一覧の制限フォルダー配下
    within '.gws-notice-folder_tree' do
      click_on limited_folder.name
    end
    wait_for_all_turbo_frames
    within '.gws-notice-folder_tree' do
      expect(page).to have_css(".ss-tree-item[data-node-id='#{public_folder.id}']", text: public_folder.name)
      expect(page).to have_css(".ss-tree-item[data-node-id='#{limited_folder.id}']", text: limited_folder.name)
    end
    within '.list-items' do
      expect(page).to have_css(".list-item[data-id='#{post_under_limited.id}']", text: post_under_limited.name)
      expect(page).to have_no_css(".list-item[data-id='#{post_under_public.id}']", text: post_under_public.name)
    end

    # 閲覧一覧 => 閲覧一覧の制限フォルダー配下へ遷移しても404になるので閲覧一覧のトップへ遷移する
    click_on I18n.t('ss.navi.readable')
    within '.gws-notice-folder_tree' do
      expect(page).to have_css(".ss-tree-item[data-node-id='#{public_folder.id}']", text: public_folder.name)
      expect(page).to have_no_css('.ss-tree-item', text: limited_folder.name)
    end
    within '.list-items' do
      expect(page).to have_css(".list-item[data-id='#{post_under_public.id}']", text: post_under_public.name)
      expect(page).to have_no_css(".list-item[data-id='#{post_under_limited.id}']", text: post_under_limited.name)
    end
  end
end
