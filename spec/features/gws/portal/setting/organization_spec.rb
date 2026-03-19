require 'spec_helper'

describe "gws_portal_setting_organization", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "least required permissions to manage" do
    let!(:notice_folder) { create(:gws_notice_folder, cur_site: site) }
    let!(:notice_post) { create(:gws_notice_post, cur_site: site, folder_id: notice_folder.id) }
    let!(:schedule_plan) { create(:gws_schedule_plan, cur_site: site) }
    let(:permissions) do
      permissions = []
      permissions << 'use_gws_portal_organization_settings'
      permissions << 'read_other_gws_portal_group_settings'
      permissions << 'edit_other_gws_portal_group_settings'
      permissions << 'delete_other_gws_portal_group_settings'
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
    let(:default_portlets) { SS.config.gws['portal']['organization_portlets'] }

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
      within ".current-navi" do
        click_on I18n.t("gws/portal.tabs.root_portal")
      end
      within ".breadcrumb" do
        expect(page).to have_content(I18n.t("gws/portal.tabs.root_portal"))
      end
      within ".current-navi" do
        expect(page).to have_content(I18n.t('gws/portal.links.arrange_portlets'))
        expect(page).to have_content(I18n.t('gws/portal.links.manage_portlets'))
        expect(page).to have_content(I18n.t('gws/portal.links.settings'))
      end

      site.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to be_blank
        expect(portal.name).to eq I18n.t("gws/portal.tabs.root_portal")
        expect(portal.portal_group_id).to eq site.id
        expect(portal.portlets.count).to eq 0
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to be_blank
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "public"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ site.id ]
        expect(portal.user_ids).to be_blank
      end

      click_on I18n.t('gws/portal.links.arrange_portlets')
      click_on I18n.t("ss.buttons.reset")
      expect(page).to have_css(".gws-portlets .portlet-model-schedule", text: schedule_plan.name)

      site.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to eq I18n.t("gws/portal.tabs.root_portal")
        expect(portal.portal_group_id).to eq site.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to eq "both"
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "public"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ site.id ]
        expect(portal.user_ids).to be_blank
      end

      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.initialize')
      within "form" do
        page.accept_alert(/#{::Regexp.escape(I18n.t("ss.confirm.initialize"))}/) do
          click_on I18n.t('ss.buttons.initialize')
        end
      end

      site.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to eq I18n.t("gws/portal.tabs.root_portal")
        expect(portal.portal_group_id).to eq site.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq "show"
        expect(portal.portal_notice_browsed_state).to eq "both"
        expect(portal.portal_monitor_state).to eq "show"
        expect(portal.portal_link_state).to eq "show"
        expect(portal.readable_setting_range).to eq "public"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ site.id ]
        expect(portal.user_ids).to be_blank
      end

      click_on I18n.t('gws/portal.links.settings')
      click_on I18n.t('ss.links.edit')
      within "form#item-form" do
        # 組織ポータルの場合、名前の変更が可能。
        # 組織ポータルには自動的に「全庁」という名称が与えられるが、一部の組織にしかマッチしそうにない。
        # そこで、組織ポータルの場合、名前の変更が可能。
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

      site.find_portal_setting(cur_user: user, cur_site: site).tap do |portal|
        expect(portal).to be_a(Gws::Portal::GroupSetting)
        expect(portal.site_id).to eq site.id
        expect(portal.user_id).to eq user.id
        expect(portal.name).to eq name
        expect(portal.portal_group_id).to eq site.id
        expect(portal.portlets.count).to eq default_portlets.size
        expect(portal.portal_notice_state).to eq portal_notice_state
        expect(portal.portal_notice_browsed_state).to eq portal_notice_browsed_state
        expect(portal.portal_monitor_state).to eq portal_monitor_state
        expect(portal.portal_link_state).to eq portal_link_state
        expect(portal.readable_setting_range).to eq "public"
        expect(portal.readable_group_ids).to be_blank
        expect(portal.readable_member_ids).to be_blank
        expect(portal.group_ids).to eq [ site.id ]
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
      permissions << 'use_gws_portal_organization_settings'
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
        click_on I18n.t("gws/portal.tabs.root_portal")
      end
      within ".breadcrumb" do
        expect(page).to have_content(I18n.t("gws/portal.tabs.root_portal"))
      end
      within ".current-navi" do
        expect(page).to have_no_content(I18n.t('gws/portal.links.arrange_portlets'))
        expect(page).to have_no_content(I18n.t('gws/portal.links.manage_portlets'))
        expect(page).to have_no_content(I18n.t('gws/portal.links.settings'))
      end
    end
  end
end
