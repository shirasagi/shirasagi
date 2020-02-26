require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) do
    create(
      :gws_user, notice_board_email_user_setting: "notify", send_notice_mail_addresses: "#{unique_id}@example.jp",
      group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
    )
  end
  let!(:category) { create :gws_board_category, subscribed_member_ids: [ user1.id ] }
  let(:now) { Time.zone.now.beginning_of_minute }

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    login_gws_user

    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "" do
    let(:release_date) { now + 1.day }
    let(:close_date) { release_date + 1.day }

    it do
      visit gws_board_topics_path(site: site, mode: '-', category: '-')
      click_on I18n.t("ss.links.new")
      click_on I18n.t("gws.apis.categories.index")
      wait_for_cbox do
        click_on category.name
      end

      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[text]", with: "text"

        select I18n.t("ss.options.state.enabled"), from: "item[notify_state]"

        within "#addon-gws-agents-addons-release" do
          first(".addon-head h2").click

          fill_in "item[release_date]", with: I18n.l(release_date, format: :picker) + "\n"
          fill_in "item[close_date]", with: I18n.l(close_date, format: :picker) + "\n"
        end

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item = Gws::Board::Topic.site(site).first
      expect(item.name).to eq "name"
      expect(item.text).to eq "text"
      expect(item.notify_state).to eq "enabled"
      expect(item.state).to eq "public"
      expect(item.release_date).to eq release_date
      expect(item.close_date).to eq close_date
      expect(item.mode).to eq "thread"
      expect(item.descendants_updated).to be_present
      expect(item.descendants_files_count).to eq 0
      expect(item.category_ids).to eq [category.id]
      expect(item.notification_noticed_at).to be_blank

      expect(SS::Notification.all.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0

      travel_to(release_date - 1.second) do
        Gws::Board::NotificationJob.bind(site_id: site.id).perform_now

        item.reload
        expect(item.notification_noticed_at).to be_blank

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0
      end

      travel_to(release_date) do
        Gws::Board::NotificationJob.bind(site_id: site.id).perform_now

        item.reload
        expect(item.notification_noticed_at).to be_present

        expect(SS::Notification.all.count).to eq 1
        notice = SS::Notification.first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to be_nil
        expect(notice.subject).to eq I18n.t("gws_notification.gws/board/topic.subject", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/board/-/-/topics/#{item.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)
      end
    end
  end
end
