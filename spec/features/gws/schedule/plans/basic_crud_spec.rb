require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:user) { gws_user }
    let!(:group) { user.groups.site(site).first }
    let(:index_path) { gws_schedule_plans_path site }
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "modify-#{unique_id}" }

    before { login_user user }

    it do
      # index
      visit index_path
      wait_for_js_ready

      # new
      click_on I18n.t("gws/schedule.links.add_plan")
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_js_ready
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Schedule::Plan.unscoped.count).to eq 1
      Gws::Schedule::Plan.unscoped.first.tap do |item|
        # Gws::Reference::User
        expect(item.user_id).to eq user.id
        expect(item.user_uid).to eq user.uid
        expect(item.user_name).to eq user.name
        expect(item.user_group_id).to eq group.id
        expect(item.user_group_name).to eq group.name
        # Gws::Reference::Site
        expect(item.site_id).to eq site.id
        # Gws::Schedule::Priority
        expect(item.priority).to be_blank
        # Gws::Schedule::Planable
        expect(item.name).to eq name
        # Gws::Addon::Member
        expect(item.member_ids).to eq [ user.id ]
        expect(item.member_group_ids).to be_blank
        expect(item.member_custom_group_ids).to be_blank
        # Gws::Addon::ReadableSetting
        expect(item.readable_setting_range).to eq "select"
        expect(item.readable_member_ids).to be_blank
        expect(item.readable_group_ids).to eq [ group.id ]
        expect(item.readable_custom_group_ids).to be_blank
        expect(item.readable_members_hash).to be_blank
        expect(item.readable_groups_hash).to include(group.id.to_s => group.name)
        expect(item.readable_custom_groups_hash).to be_blank
        # Gws::Addon::GroupPermission
        expect(item.user_ids).to eq [ user.id ]
        expect(item.group_ids).to eq [ group.id ]
        expect(item.custom_group_ids).to be_blank
        expect(item.users_hash).to include(user.id.to_s => user.long_name)
        expect(item.groups_hash).to include(group.id.to_s => group.name)
        expect(item.custom_groups_hash).to be_blank
      end

      # events
      today = Time.zone.today
      sdate = today - today.day + 1.day
      edate = sdate + 1.month
      visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
      expect(page.body).to have_content(name)

      # show & edit
      visit index_path
      wait_for_js_ready
      expect(page).to have_css(".fc-event-container", text: name)

      # click_on name
      within ".fc-event-container" do
        first(".fc-event .fc-content", text: name).click
      end
      wait_for_js_ready
      expect(page).to have_content(name)

      click_on I18n.t("ss.links.edit")
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_js_ready
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Schedule::Plan.unscoped.count).to eq 1
      Gws::Schedule::Plan.unscoped.first.tap do |item|
        expect(item.name).to eq name2
      end

      # delete
      visit index_path
      wait_for_js_ready
      expect(page).to have_content(name2)

      # click_on name2
      within ".fc-event-container" do
        first(".fc-event .fc-content", text: name2).click
      end
      wait_for_js_ready
      expect(page).to have_content(name2)

      click_on I18n.t("ss.links.delete")
      wait_for_js_ready
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_js_ready
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Schedule::Plan.unscoped.count).to eq 1
      Gws::Schedule::Plan.unscoped.first.tap do |item|
        expect(item.name).to eq name2
        expect(item.deleted).to be_present
      end
    end
  end
end
