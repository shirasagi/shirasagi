require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, notice_schedule_user_setting: "notify") }
  let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, notice_schedule_user_setting: "notify") }
  let!(:plan1) { create :gws_schedule_plan, cur_user: gws_user, notify_state: "enabled", member_ids: [ gws_user.id, user1.id, user2.id ], user_ids: [ gws_user.id ] }
  let!(:plan2) { create :gws_schedule_plan, cur_user: gws_user, notify_state: "enabled", member_ids: [ gws_user.id, user1.id, user2.id ], user_ids: [ gws_user.id ] }

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    login_gws_user

    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "unrelated plan notification are sent when plan is deleted" do
    it do
      visit gws_schedule_plan_path(site: site, id: plan1)
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      puts "plan1.name=#{plan1.name}, plan2.name=#{plan2.name}"
      puts "notification=#{SS::Notification.all.pluck(:subject).join(", ")}"
      expect(SS::Notification.count).to eq 1
    end
  end
end
