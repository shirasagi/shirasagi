require 'spec_helper'

describe "sys_conf", type: :feature, dbscope: :example do
  context "with user which is permitted all" do
    before do
      role = create(:sys_role_admin, name: unique_id)
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      click_on 'システム設定'
      expect(current_path).to eq sys_conf_path
      within 'nav.mod-navi' do
        expect(page).to have_css('h2 a', text: 'システム設定')
        expect(page).to have_css('h3 a', text: 'システム情報')
        expect(page).to have_css('h3 a', text: 'サイト')
        expect(page).to have_css('h3 a', text: 'グループ')
        expect(page).to have_css('h3 a', text: 'ユーザー')
        expect(page).to have_css('h3 a', text: '権限/ロール')
        expect(page).to have_css('h3 a', text: '認証')
        expect(page).to have_css('h3 a', text: '最大ファイルサイズ')
        expect(page).to have_css('h3 a', text: 'サイト複製')
        expect(page).to have_css('h3 a', text: 'テスト')
        expect(page).to have_css('h3 a', text: '操作履歴')
        expect(page).to have_css('h3 a', text: 'ジョブ')
      end
    end
  end

  context "with user which is permitted only edit_sys_groups" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_groups))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      click_on 'システム設定'
      expect(current_path).to eq sys_conf_path
      within 'nav.mod-navi' do
        expect(page).to     have_css('h2 a', text: 'システム設定')
        expect(page).to     have_css('h3 a', text: 'システム情報')
        expect(page).not_to have_css('h3 a', text: 'サイト')
        expect(page).to     have_css('h3 a', text: 'グループ')
        expect(page).not_to have_css('h3 a', text: 'ユーザー')
        expect(page).not_to have_css('h3 a', text: '権限/ロール')
        expect(page).not_to have_css('h3 a', text: '認証')
        expect(page).not_to have_css('h3 a', text: '最大ファイルサイズ')
        expect(page).not_to have_css('h3 a', text: 'サイト複製')
        expect(page).not_to have_css('h3 a', text: 'テスト')
        expect(page).not_to have_css('h3 a', text: '操作履歴')
        expect(page).not_to have_css('h3 a', text: 'ジョブ')
      end
    end
  end

  context "with user which is permitted only edit_sys_roles" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_roles))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      click_on 'システム設定'
      expect(current_path).to eq sys_conf_path
      within 'nav.mod-navi' do
        expect(page).to     have_css('h2 a', text: 'システム設定')
        expect(page).to     have_css('h3 a', text: 'システム情報')
        expect(page).not_to have_css('h3 a', text: 'サイト')
        expect(page).not_to have_css('h3 a', text: 'グループ')
        expect(page).not_to have_css('h3 a', text: 'ユーザー')
        expect(page).to     have_css('h3 a', text: '権限/ロール')
        expect(page).not_to have_css('h3 a', text: '認証')
        expect(page).not_to have_css('h3 a', text: '最大ファイルサイズ')
        expect(page).not_to have_css('h3 a', text: 'サイト複製')
        expect(page).not_to have_css('h3 a', text: 'テスト')
        expect(page).not_to have_css('h3 a', text: '操作履歴')
        expect(page).not_to have_css('h3 a', text: 'ジョブ')
      end
    end
  end

  context "with user which is permitted only edit_sys_sites" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_sites))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      click_on 'システム設定'
      expect(current_path).to eq sys_conf_path
      within 'nav.mod-navi' do
        expect(page).to     have_css('h2 a', text: 'システム設定')
        expect(page).to     have_css('h3 a', text: 'システム情報')
        expect(page).to     have_css('h3 a', text: 'サイト')
        expect(page).not_to have_css('h3 a', text: 'グループ')
        expect(page).not_to have_css('h3 a', text: 'ユーザー')
        expect(page).not_to have_css('h3 a', text: '権限/ロール')
        expect(page).not_to have_css('h3 a', text: '認証')
        expect(page).not_to have_css('h3 a', text: '最大ファイルサイズ')
        expect(page).to     have_css('h3 a', text: 'サイト複製')
        expect(page).not_to have_css('h3 a', text: 'テスト')
        expect(page).not_to have_css('h3 a', text: '操作履歴')
        expect(page).not_to have_css('h3 a', text: 'ジョブ')
      end
    end
  end

  context "with user which is permitted only edit_sys_users" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_users))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      click_on 'システム設定'
      expect(current_path).to eq sys_conf_path
      within 'nav.mod-navi' do
        expect(page).to     have_css('h2 a', text: 'システム設定')
        expect(page).to     have_css('h3 a', text: 'システム情報')
        expect(page).not_to have_css('h3 a', text: 'サイト')
        expect(page).not_to have_css('h3 a', text: 'グループ')
        expect(page).to     have_css('h3 a', text: 'ユーザー')
        expect(page).not_to have_css('h3 a', text: '権限/ロール')
        expect(page).to     have_css('h3 a', text: '認証')
        expect(page).to     have_css('h3 a', text: '最大ファイルサイズ')
        expect(page).not_to have_css('h3 a', text: 'サイト複製')
        expect(page).to     have_css('h3 a', text: 'テスト')
        expect(page).to     have_css('h3 a', text: '操作履歴')
        expect(page).to     have_css('h3 a', text: 'ジョブ')
      end
    end
  end

  context "with user which is permitted nothing" do
    before do
      user = create(:sys_user_sample, sys_role_ids: [])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      click_on 'システム設定'
      expect(current_path).to eq sys_conf_path
      within 'nav.mod-navi' do
        expect(page).to     have_css('h2 a', text: 'システム設定')
        expect(page).to     have_css('h3 a', text: 'システム情報')
        expect(page).not_to have_css('h3 a', text: 'サイト')
        expect(page).not_to have_css('h3 a', text: 'グループ')
        expect(page).not_to have_css('h3 a', text: 'ユーザー')
        expect(page).not_to have_css('h3 a', text: '権限/ロール')
        expect(page).not_to have_css('h3 a', text: '認証')
        expect(page).not_to have_css('h3 a', text: '最大ファイルサイズ')
        expect(page).not_to have_css('h3 a', text: 'サイト複製')
        expect(page).not_to have_css('h3 a', text: 'テスト')
        expect(page).not_to have_css('h3 a', text: '操作履歴')
        expect(page).not_to have_css('h3 a', text: 'ジョブ')
      end
    end
  end
end
