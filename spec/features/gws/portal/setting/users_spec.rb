require 'spec_helper'

describe "gws_portal_setting_users", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit gws_portal_path(site: site)
      expect(page).to have_no_content(I18n.t('gws/portal.user_portal'))

      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_content(I18n.t('gws/portal.user_portal'))

      visit gws_portal_setting_users_path(site: site)
      expect(page).to have_content(user.name)

      # secured
      role = user.gws_roles[0]
      role.update(permissions: [])
      user.clear_gws_role_permissions

      visit gws_site_path(site: site)
      expect(page).to have_no_content(I18n.t('gws/portal.user_portal'))

      visit gws_portal_setting_users_path(site: site)
      expect(page).to have_title("403")
    end
  end

  context "least required permissions to manage" do
    let!(:notice_folder) { create(:gws_notice_folder, cur_site: site) }
    let!(:notice_post) { create(:gws_notice_post, cur_site: site, folder_id: notice_folder.id) }
    let!(:schedule_plan) { create(:gws_schedule_plan, cur_site: site) }
    let(:permissions) do
      permissions = []
      permissions << 'use_gws_portal_user_settings'
      permissions << 'read_private_gws_portal_user_settings'
      permissions << 'edit_private_gws_portal_user_settings'
      permissions << 'delete_private_gws_portal_user_settings'
      # ポータルにお知らせを表示するために必要
      permissions << 'use_gws_notice'
      permissions << 'read_private_gws_notices'
      # ポータルにスケジュールを表示するために必要
      permissions << 'use_private_gws_schedule_plans'
      permissions << 'read_private_gws_schedule_plans'
      permissions
    end
    let(:role) { create(:gws_role, cur_site: site, permissions: permissions) }
    let(:default_portlets) { SS.config.gws['portal']['user_portlets'] }

    before do
      user.gws_role_ids = [role.id]
      user.save!

      login_user user
    end

    it do
      visit gws_portal_path(site: site)
      expect(page).to have_css(".gws-notices", text: notice_post.name)
      expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
      within ".current-navi" do
        click_on I18n.t("gws/portal.tabs.user_portal")
      end
      within ".breadcrumb" do
        expect(page).to have_content(I18n.t('gws/portal.user_portal'))
      end
      within ".current-navi" do
        expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
        expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
        expect(page).to have_content(I18n.t('gws/portal.links.settings'))
      end

      user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::UserSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to be_blank
        expect(portal.name).to include(user.name)
        expect(portal.name).to include(user.uid)
        expect(portal.portal_user_id).to eq user.id
        expect(portal.portlets.count).to eq 0
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to be_blank
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to eq [ user.id ]
        expect(portal.group_ids).to be_blank
        expect(portal.user_ids).to eq [ user.id ]
      end

      click_on I18n.t('gws/portal.links.arrange_portlets')
      click_on I18n.t("ss.buttons.reset")
      expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)

      user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::UserSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to include(user.name)
        expect(portal.name).to include(user.uid)
        expect(portal.portal_user_id).to eq user.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to eq "both"
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to eq [ user.id ]
        expect(portal.group_ids).to be_blank
        expect(portal.user_ids).to eq [ user.id ]
      end

      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.initialize')
      within "form" do
        page.accept_alert(/#{::Regexp.escape(I18n.t("ss.confirm.initialize"))}/) do
          click_on I18n.t('ss.buttons.initialize')
        end
      end

      user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::UserSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to include(user.name)
        expect(portal.name).to include(user.uid)
        expect(portal.portal_user_id).to eq user.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to eq "both"
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to eq [ user.id ]
        expect(portal.group_ids).to be_blank
        expect(portal.user_ids).to eq [ user.id ]
      end

      click_on I18n.t('gws/portal.links.settings')
      click_on I18n.t('ss.links.edit')
      within "form" do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::UserSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to include(user.name)
        expect(portal.name).to include(user.uid)
        expect(portal.portal_user_id).to eq user.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to eq "both"
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to eq [ user.id ]
        expect(portal.group_ids).to be_blank
        expect(portal.user_ids).to eq [ user.id ]
      end
    end
  end

  context "least required permissions to show" do
    let!(:notice_folder) { create(:gws_notice_folder, cur_site: site) }
    let!(:notice_post) { create(:gws_notice_post, cur_site: site, folder_id: notice_folder.id) }
    let!(:schedule_plan) { create(:gws_schedule_plan, cur_site: site) }
    let(:permissions) do
      permissions = []
      permissions << 'use_gws_portal_user_settings'
      # ポータルにお知らせを表示するために必要
      permissions << 'use_gws_notice'
      permissions << 'read_private_gws_notices'
      # ポータルにスケジュールを表示するために必要
      permissions << 'use_private_gws_schedule_plans'
      permissions << 'read_private_gws_schedule_plans'
      permissions
    end
    let(:role) { create(:gws_role, cur_site: site, permissions: permissions) }

    before do
      user.gws_role_ids = [role.id]
      user.save!

      login_user user
    end

    it do
      visit gws_portal_path(site: site)
      expect(page).to have_css(".gws-notices", text: notice_post.name)
      expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
      within ".current-navi" do
        click_on I18n.t("gws/portal.tabs.user_portal")
      end
      within ".breadcrumb" do
        expect(page).to have_content(I18n.t('gws/portal.user_portal'))
      end
      within ".current-navi" do
        expect(page).to have_no_content(I18n.t('gws/portal.links.arrange_portlets'))
        expect(page).to have_no_content(I18n.t('gws/portal.links.manage_portlets'))
        expect(page).to have_no_content(I18n.t('gws/portal.links.settings'))
      end
    end
  end

  # ユースケース: 氏名変更
  context "case: name change" do
    let(:permissions) do
      permissions = []
      permissions << 'use_gws_portal_user_settings'
      permissions << 'read_private_gws_portal_user_settings'
      permissions << 'edit_private_gws_portal_user_settings'
      permissions << 'delete_private_gws_portal_user_settings'
      # ポータルにお知らせを表示するために必要
      permissions << 'use_gws_notice'
      permissions << 'read_private_gws_notices'
      # ポータルにスケジュールを表示するために必要
      permissions << 'use_private_gws_schedule_plans'
      permissions << 'read_private_gws_schedule_plans'
      permissions
    end
    let!(:role) { create(:gws_role, cur_site: site, permissions: permissions) }
    let!(:user) do
      create(
        :gws_user, cur_site: site, name: "木下 藤吉郎", uid: unique_id,
        group_ids: gws_user.group_ids, gws_role_ids: [ role.id ])
    end

    let!(:notice_folder) { create(:gws_notice_folder, cur_site: site) }
    let!(:notice_post) { create(:gws_notice_post, cur_site: site, folder_id: notice_folder.id) }
    let!(:schedule_plan) { create(:gws_schedule_plan, cur_site: site, member_ids: [ gws_user.id, user.id ]) }

    let(:default_portlets) { SS.config.gws['portal']['user_portlets'] }

    context "name reflection with reset by myself" do
      it do
        login_user user, to: gws_portal_path(site: site)
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".current-navi" do
          click_on I18n.t("gws/portal.tabs.user_portal")
        end
        within ".breadcrumb" do
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
        end
        within ".current-navi" do
          expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.settings'))
        end

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to be_blank
          expect(portal.name).to include("木下 藤吉郎")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq 0
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to be_blank
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end

        # 氏名変更
        Gws::User.find(user.id).tap do |user_work|
          user_work.update!(name: "羽柴 秀吉")
        end

        within ".current-navi" do
          click_on I18n.t('gws/portal.links.arrange_portlets')
        end
        within ".nav-menu" do
          click_on I18n.t("ss.buttons.reset")
        end
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to eq user.id
          expect(portal.name).not_to include("木下 藤吉郎")
          expect(portal.name).to include("羽柴 秀吉")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq default_portlets.size
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to eq "both"
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end
      end
    end

    context "name reflection with initialize by myself" do
      it do
        login_user user, to: gws_portal_path(site: site)
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".current-navi" do
          click_on I18n.t("gws/portal.tabs.user_portal")
        end
        within ".breadcrumb" do
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
        end
        within ".current-navi" do
          expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.settings'))
        end

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to be_blank
          expect(portal.name).to include("木下 藤吉郎")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq 0
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to be_blank
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end

        # 氏名変更
        Gws::User.find(user.id).tap do |user_work|
          user_work.update!(name: "羽柴 秀吉")
        end

        within ".current-navi" do
          click_on I18n.t('gws/portal.links.manage_portlets')
        end
        within ".nav-menu" do
          click_on I18n.t('ss.links.initialize')
        end
        within "form" do
          page.accept_alert(/#{::Regexp.escape(I18n.t("ss.confirm.initialize"))}/) do
            click_on I18n.t('ss.buttons.initialize')
          end
        end

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to eq user.id
          expect(portal.name).not_to include("木下 藤吉郎")
          expect(portal.name).to include("羽柴 秀吉")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq default_portlets.size
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to eq "both"
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end
      end
    end

    context "name reflection with setting edit by myself" do
      it do
        login_user user, to: gws_portal_path(site: site)
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".current-navi" do
          click_on I18n.t("gws/portal.tabs.user_portal")
        end
        within ".breadcrumb" do
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
        end
        within ".current-navi" do
          expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.settings'))
        end

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to be_blank
          expect(portal.name).to include("木下 藤吉郎")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq 0
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to be_blank
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end

        # 氏名変更
        Gws::User.find(user.id).tap do |user_work|
          user_work.update!(name: "羽柴 秀吉")
        end

        within ".current-navi" do
          click_on I18n.t('gws/portal.links.settings')
        end
        within ".nav-menu" do
          click_on I18n.t('ss.links.edit')
        end
        # 何も変更せずに保存する
        within "form#item-form" do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to eq user.id
          expect(portal.name).not_to include("木下 藤吉郎")
          expect(portal.name).to include("羽柴 秀吉")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq default_portlets.size
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to eq "both"
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end
      end
    end

    context "name reflection with reset by admin" do
      it do
        login_user gws_user, to: gws_portal_path(site: site)
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)

        within ".current-navi" do
          click_on I18n.t("gws/portal.tabs.user_portal")
        end
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".breadcrumb" do
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
        end
        within ".current-navi" do
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
          expect(page).to have_content(I18n.t('gws/portal.group_portal'))

          click_on I18n.t('gws/portal.user_portal')
        end

        within ".list-items" do
          click_on "木下 藤吉郎"
        end
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".breadcrumb" do
          expect(page).to have_content("木下 藤吉郎")
        end
        within ".current-navi" do
          expect(page).to have_content("木下 藤吉郎")
          expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.settings'))
        end

        user.find_portal_setting(cur_user: gws_user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to be_blank
          expect(portal.name).to include("木下 藤吉郎")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq 0
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to be_blank
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end

        # 氏名変更
        Gws::User.find(user.id).tap do |user_work|
          user_work.update!(name: "羽柴 秀吉")
        end

        within ".current-navi" do
          click_on I18n.t('gws/portal.links.arrange_portlets')
        end
        within ".nav-menu" do
          click_on I18n.t("ss.buttons.reset")
        end
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".breadcrumb" do
          expect(page).to have_content("羽柴 秀吉")
        end
        within ".current-navi" do
          expect(page).to have_content("羽柴 秀吉")
          expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.settings'))
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
          expect(page).to have_content(I18n.t('gws/portal.group_portal'))
        end

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to eq gws_user.id
          expect(portal.name).not_to include("木下 藤吉郎")
          expect(portal.name).to include("羽柴 秀吉")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq default_portlets.size
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to eq "both"
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end

        within ".current-navi" do
          click_on I18n.t('gws/portal.user_portal')
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", text: "羽柴 秀吉")
          click_on "羽柴 秀吉"
        end
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".breadcrumb" do
          expect(page).to have_content("羽柴 秀吉")
        end
        within ".current-navi" do
          expect(page).to have_content("羽柴 秀吉")
        end
      end
    end

    context "name reflection with setting edit by admin" do
      it do
        login_user gws_user, to: gws_portal_path(site: site)
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)

        within ".current-navi" do
          click_on I18n.t("gws/portal.tabs.user_portal")
        end
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".breadcrumb" do
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
        end
        within ".current-navi" do
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
          expect(page).to have_content(I18n.t('gws/portal.group_portal'))

          click_on I18n.t('gws/portal.user_portal')
        end

        within ".list-items" do
          click_on "木下 藤吉郎"
        end
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".breadcrumb" do
          expect(page).to have_content("木下 藤吉郎")
        end
        within ".current-navi" do
          expect(page).to have_content("木下 藤吉郎")
          expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.settings'))
        end

        user.find_portal_setting(cur_user: gws_user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to be_blank
          expect(portal.name).to include("木下 藤吉郎")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq 0
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to be_blank
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end

        # 氏名変更
        Gws::User.find(user.id).tap do |user_work|
          user_work.update!(name: "羽柴 秀吉")
        end

        within ".current-navi" do
          click_on I18n.t('gws/portal.links.settings')
        end
        within ".nav-menu" do
          click_on I18n.t('ss.links.edit')
        end
        # 何も変更せずに保存する
        within "form#item-form" do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        within ".breadcrumb" do
          expect(page).to have_content("羽柴 秀吉")
        end
        within ".current-navi" do
          expect(page).to have_content("羽柴 秀吉")
          expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
          expect(page).to have_content(I18n.t('gws/portal.links.settings'))
          expect(page).to have_content(I18n.t('gws/portal.user_portal'))
          expect(page).to have_content(I18n.t('gws/portal.group_portal'))
        end

        user.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
          expect(portal).to be_a(Gws::Portal::UserSetting)
          expect(portal.site_id).to eq site.id
          expect(portal.user_id).to eq gws_user.id
          expect(portal.name).not_to include("木下 藤吉郎")
          expect(portal.name).to include("羽柴 秀吉")
          expect(portal.name).to include(user.uid)
          expect(portal.portal_user_id).to eq user.id
          expect(portal.portlets.count).to eq default_portlets.size
          expect(portal.portal_notice_state).to eq "show"
          expect(portal.portal_notice_browsed_state).to eq "both"
          expect(portal.portal_monitor_state).to eq "show"
          expect(portal.portal_link_state).to eq "show"
          expect(portal.readable_setting_range).to eq "select"
          expect(portal.readable_group_ids).to be_blank
          expect(portal.readable_member_ids).to eq [ user.id ]
          expect(portal.group_ids).to be_blank
          expect(portal.user_ids).to eq [ user.id ]
        end

        within ".current-navi" do
          click_on I18n.t('gws/portal.user_portal')
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", text: "羽柴 秀吉")
          click_on "羽柴 秀吉"
        end
        expect(page).to have_css(".gws-notices", text: notice_post.name)
        expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
        within ".breadcrumb" do
          expect(page).to have_content("羽柴 秀吉")
        end
        within ".current-navi" do
          expect(page).to have_content("羽柴 秀吉")
        end
      end
    end
  end
end
