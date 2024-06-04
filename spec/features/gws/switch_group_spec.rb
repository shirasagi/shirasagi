require 'spec_helper'

describe "gws_switch_group", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:default_group) { gws_user.groups.first }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  before do
    Gws::User.find(gws_user.id).tap do |user|
      # メンバー変数が汚染されるとテストで思わぬ結果をうむ場合がある。
      # そこで、データベースからユーザーをロードし、必要処理を実行後、インスタンスを破棄する。
      user.cur_site = site
      user.in_gws_main_group_id = default_group.id
      user.group_ids = user.group_ids + [ group1.id, group2.id, group3.id ]
      user.save!
    end
    gws_user.reload

    login_gws_user
  end

  context "when group is changed" do
    it do
      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids[site.id.to_s]).to eq default_group.id
        expect(user.gws_default_group_ids).to be_blank
      end
      visit gws_portal_path(site: site)

      within "nav.user" do
        # click_on user.name
        Gws::User.find(gws_user.id).tap do |user|
          user.cur_site = site
          expect(page).to have_css(".user-navigation-user-id", text: "#{user.gws_default_group.trailing_name} #{user.name}")
          wait_for_event_fired("turbo:frame-load") { click_on user.name }
        end

        within "#user-main-dropdown" do
          wait_for_event_fired("turbo:frame-load") { click_on I18n.t("gws.links.switch_group") }
        end

        within "#gws-group-switch-form" do
          expect(page).to have_css(".gws-group-switch-name", text: group1.section_name)
          expect(page).to have_css(".gws-group-switch-name", text: group2.section_name)
          expect(page).to have_css(".gws-group-switch-name", text: group3.section_name)

          # click_on group2.section_name
          within "#gws-group-switch-menu-#{group2.id}" do
            find(".gws-group-switch-name").click
          end
        end
      end
      wait_for_notice I18n.t("gws.notice.default_group_changed")

      within "nav.user" do
        expect(page).to have_css(".user-navigation-user-id", text: "#{group2.trailing_name} #{gws_user.name}")
      end
      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to include(site.id.to_s => default_group.id)
        expect(user.gws_default_group_ids).to include(site.id.to_s => group2.id)
      end
    end
  end

  context "on modal" do
    let!(:user_in_default_group) { create :gws_user, group_ids: [ default_group.id ] }
    let!(:user_in_group2) { create :gws_user, group_ids: [ group2.id ] }

    it do
      visit new_gws_schedule_plan_path(site: site)
      within "#item-form" do
        # 閲覧権限と管理権限の初期値として、「グループ（既定）」が設定されていることを確認する
        within "#addon-gws-agents-addons-readable_setting" do
          expect(page).to have_css(".gws-addon-readable-setting-group", text: default_group.name)
        end
        within "#addon-gws-agents-addons-group_permission" do
          expect(page).to have_css(".mod-gws-owner_permission-groups", text: default_group.name)
        end

        within "#addon-gws-agents-addons-member" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.apis.users.index")
          end
        end
      end
      within_cbox do
        # モーダルでも「グループ（既定）」が設定されていることを確認する
        expect(page).to have_css(".list-item", text: user_in_default_group.long_name)
      end

      visit new_gws_schedule_plan_path(site: site)
      within "nav.user" do
        wait_for_event_fired("turbo:frame-load") { click_on gws_user.name }

        within "#user-main-dropdown" do
          wait_for_event_fired("turbo:frame-load") { click_on I18n.t("gws.links.switch_group") }
        end

        within "#gws-group-switch-form" do
          # click_on group2.section_name
          within "#gws-group-switch-menu-#{group2.id}" do
            find(".gws-group-switch-name").click
          end
        end
      end
      wait_for_notice I18n.t("gws.notice.default_group_changed")

      within "#item-form" do
        # 閲覧権限と管理権限の初期値として、「グループ（既定）」が設定されていることを確認する
        within "#addon-gws-agents-addons-readable_setting" do
          expect(page).to have_css(".gws-addon-readable-setting-group", text: group2.name)
        end
        within "#addon-gws-agents-addons-group_permission" do
          expect(page).to have_css(".mod-gws-owner_permission-groups", text: group2.name)
        end

        within "#addon-gws-agents-addons-member" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.apis.users.index")
          end
        end
      end
      within_cbox do
        # モーダルでも「グループ（既定）」が設定されていることを確認する
        expect(page).to have_css(".list-item", text: user_in_group2.long_name)
      end
    end
  end
end
