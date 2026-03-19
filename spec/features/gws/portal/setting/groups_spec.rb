require 'spec_helper'

describe "gws_portal_setting_groups", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit gws_portal_path(site: site)
      expect(page).to have_no_content(I18n.t('gws/portal.group_portal'))

      visit gws_portal_group_path(site: site, group: site)
      expect(page).to have_content(I18n.t('gws/portal.group_portal'))

      visit gws_portal_setting_groups_path(site: site)
      expect(page).to have_content(user.groups.first.trailing_name)

      # secured
      role = user.gws_roles[0]
      role.update(permissions: [])
      user.clear_gws_role_permissions

      visit gws_site_path(site: site)
      expect(page).to have_no_content(I18n.t('gws/portal.group_portal'))

      visit gws_portal_setting_groups_path(site: site)
      expect(page).to have_title("403")
    end
  end

  context "least required permissions to manage" do
    let!(:notice_folder) { create(:gws_notice_folder, cur_site: site) }
    let!(:notice_post) { create(:gws_notice_post, cur_site: site, folder_id: notice_folder.id) }
    let!(:schedule_plan) { create(:gws_schedule_plan, cur_site: site) }
    let(:permissions) do
      permissions = []
      permissions << 'use_gws_portal_group_settings'
      permissions << 'read_private_gws_portal_group_settings'
      permissions << 'edit_private_gws_portal_group_settings'
      permissions << 'delete_private_gws_portal_group_settings'
      # ポータルにお知らせを表示するために必要
      permissions << 'use_gws_notice'
      permissions << 'read_private_gws_notices'
      # ポータルにスケジュールを表示するために必要
      permissions << 'use_private_gws_schedule_plans'
      permissions << 'read_private_gws_schedule_plans'
      # 設定に照会回答の設定項目を表示するために必要
      permissions << 'use_gws_monitor'
      permissions << 'read_private_gws_monitor_posts'
      permissions
    end
    let(:role) { create(:gws_role, cur_site: site, permissions: permissions) }
    let(:default_portlets) { SS.config.gws['portal']['group_portlets'] }

    let(:name) { "name-#{unique_id}" }
    let(:portal_notice_state) { %w(show hide).sample }
    let(:portal_notice_state_label) { I18n.t("ss.options.state.#{portal_notice_state}") }
    let(:portal_notice_browsed_state) { %w(both unread read).sample }
    let(:portal_notice_browsed_state_label) { I18n.t("gws/board.options.browsed_state.#{portal_notice_browsed_state}") }
    let(:portal_monitor_state) { %w(show hide).sample }
    let(:portal_monitor_state_label) { I18n.t("ss.options.state.#{portal_monitor_state}") }
    let(:portal_link_state) { %w(show hide).sample }
    let(:portal_link_state_label) { I18n.t("ss.options.state.#{portal_link_state}") }

    before do
      user.gws_role_ids = [role.id]
      user.save!

      login_user user
    end

    it do
      visit gws_portal_path(site: site)
      expect(page).to have_css(".gws-notices", text: notice_post.name)
      expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)
      group = user.groups.first
      within ".current-navi" do
        click_on group.trailing_name
      end
      within ".breadcrumb" do
        expect(page).to have_content(group.trailing_name)
      end
      within ".current-navi" do
        expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
        expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
        expect(page).to have_content(I18n.t('gws/portal.links.settings'))
      end

      group.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to be_blank
        expect(portal.name).to eq group.trailing_name
        expect(portal.portal_group_id).to eq group.id
        expect(portal.portlets.count).to eq 0
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to be_blank
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to eq [ group.id ]
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ group.id ]
        expect(portal.user_ids).to be_blank
      end

      click_on I18n.t('gws/portal.links.arrange_portlets')
      click_on I18n.t("ss.buttons.reset")
      expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)

      group.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to eq group.trailing_name
        expect(portal.portal_group_id).to eq group.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to eq "both"
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to eq [ group.id ]
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ group.id ]
        expect(portal.user_ids).to be_blank
      end

      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.initialize')
      within "form" do
        page.accept_alert(/#{::Regexp.escape(I18n.t("ss.confirm.initialize"))}/) do
          click_on I18n.t('ss.buttons.initialize')
        end
      end

      group.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to eq group.trailing_name
        expect(portal.portal_group_id).to eq group.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to eq "both"
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to eq [ group.id ]
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ group.id ]
        expect(portal.user_ids).to be_blank
      end

      click_on I18n.t('gws/portal.links.settings')
      click_on I18n.t('ss.links.edit')
      within "form#item-form" do
        # グループポータルの場合、名前の変更が可能
        # 理解としては、組織ポータルの名称を変更できるようにしたら、シラサギの都合上、グループの名前も変更出来てしまう。
        expect(page).to have_field("item[name]")
        fill_in "item[name]", with: name

        # gws/addon/portal/notice_setting
        select portal_notice_state_label, from: "item[portal_notice_state]"
        select portal_notice_browsed_state_label, from: "item[portal_notice_browsed_state]"

        # gws/addon/portal/monitor_setting
        select portal_monitor_state_label, from: "item[portal_monitor_state]"

        # gws/addon/portal/link_setting
        select portal_link_state_label, from: "item[portal_link_state]"

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      group.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to eq name
        expect(portal.portal_group_id).to eq group.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq portal_notice_state
        expect(portal.portal_notice_browsed_state).to eq portal_notice_browsed_state
        expect(portal.portal_monitor_state).to eq portal_monitor_state
        expect(portal.portal_link_state).to eq portal_link_state
        expect(portal.readable_setting_range).to eq "select"
        expect(portal.readable_group_ids).to eq [ group.id ]
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ group.id ]
        expect(portal.user_ids).to be_blank
      end
    end
  end

  context "least required permissions to show" do
    let!(:notice_folder) { create(:gws_notice_folder, cur_site: site) }
    let!(:notice_post) { create(:gws_notice_post, cur_site: site, folder_id: notice_folder.id) }
    let!(:schedule_plan) { create(:gws_schedule_plan, cur_site: site) }
    let(:permissions) do
      permissions = []
      permissions << 'use_gws_portal_group_settings'
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
        click_on user.groups.first.trailing_name
      end
      within ".breadcrumb" do
        expect(page).to have_content(user.groups.first.trailing_name)
      end
      within ".current-navi" do
        expect(page).to have_no_content(I18n.t('gws/portal.links.arrange_portlets'))
        expect(page).to have_no_content(I18n.t('gws/portal.links.manage_portlets'))
        expect(page).to have_no_content(I18n.t('gws/portal.links.settings'))
      end
    end
  end
end
