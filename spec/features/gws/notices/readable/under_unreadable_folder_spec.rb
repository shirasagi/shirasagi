require 'spec_helper'

describe "gws_notices_readables", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:role) do
    create :gws_role, :gws_role_notice_reader,
           :gws_role_portal_user_use, :gws_role_portal_group_use, :gws_role_portal_organization_use, cur_site: site
  end
  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user) { create :gws_user, cur_site: site, gws_role_ids: [ role.id ], group_ids: [ group.id ] }
  let!(:folder) do
    create(
      :gws_notice_folder, cur_site: site, member_group_ids: [], member_ids: [ admin.id ],
      readable_setting_range: "select", readable_group_ids: [], readable_member_ids: [ admin.id ],
      group_ids: [], user_ids: [ admin.id ])
  end
  let!(:item1) do
    # admin しか閲覧権限のないフォルダー配下の全公開のお知らせ
    create(
      :gws_notice_post, cur_site: site, cur_user: admin, folder: folder, readable_setting_range: "public", state: "public")
  end
  let!(:item2) do
    # admin しか閲覧権限のないフォルダー配下の全公開のお知らせ（バックナンバー）
    create(
      :gws_notice_post, cur_site: site, cur_user: admin, folder: folder, readable_setting_range: "public",
      state: "public", close_date: now - 1.hour)
  end

  let!(:user_portal) { create :gws_portal_user_setting, cur_user: user, portal_user: user }
  let!(:user_portlet) do
    create :gws_portal_user_portlet, :gws_portal_notice_portlet, cur_user: user, setting: user_portal
  end
  let!(:group_portal) { create :gws_portal_group_setting, cur_user: user, portal_group: group }
  let!(:group_portlet) do
    create :gws_portal_group_portlet, :gws_portal_notice_portlet, cur_user: user, setting: group_portal
  end
  let!(:site_portal) { create :gws_portal_group_setting, cur_user: user, portal_group: site }
  let!(:site_portlet) do
    create :gws_portal_group_portlet, :gws_portal_notice_portlet, cur_user: user, setting: site_portal
  end

  # 閲覧できないフォルダー配下の閲覧可能なお知らせ
  # 奇妙な動作だけど、これを前提にしているケースがある。
  context "given a readable post under unreadable folder" do
    it do
      # お知らせ - 閲覧一覧
      login_user user, to: gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames
      expect(page).to have_css(".list-item[data-id='#{item1.id}']", text: item1.name)
      expect(page).to have_no_css(".tree-navi")

      # お知らせ - 閲覧明細
      click_on item1.name
      expect(page).to have_css("#addon-basic", text: item1.name)

      # お知らせ - バックナンバー一覧
      visit gws_notice_back_numbers_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames
      expect(page).to have_css(".list-item[data-id='#{item2.id}']", text: item2.name)
      expect(page).to have_no_css(".tree-navi")

      # お知らせ - バックナンバー明細
      click_on item2.name
      expect(page).to have_css("#addon-basic", text: item2.name)

      # ポータル - メイン
      visit gws_portal_path(site: site)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end

      # ポータル - 個人
      visit gws_portal_user_path(site: site, user: user)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end

      # ポータル - グループ
      visit gws_portal_group_path(site: site, group: group)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end

      # ポータル - 全庁
      visit gws_portal_group_path(site: site, group: site)
      wait_for_all_turbo_frames
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end
      within ".portlets .gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
      end
    end
  end
end
