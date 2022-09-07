require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, notice_schedule_user_setting: "notify") }
  let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, notice_schedule_user_setting: "notify") }
  let!(:plan1) do
    create(
      :gws_schedule_plan, cur_user: gws_user, notify_state: "enabled", member_ids: [ gws_user.id, user1.id ],
      user_ids: [ gws_user.id ]
    )
  end
  let!(:plan2) do
    create(
      :gws_schedule_plan, cur_user: gws_user, notify_state: "enabled", member_ids: [ gws_user.id, user2.id ],
      user_ids: [ gws_user.id ]
    )
  end

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
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(SS::Notification.count).to eq 1
      SS::Notification.first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan/destroy.subject", name: plan1.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.user_settings).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to be_blank
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end
    end
  end
end
