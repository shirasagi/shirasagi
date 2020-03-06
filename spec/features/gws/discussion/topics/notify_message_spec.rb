require 'spec_helper'

describe "gws_discussion_topics_notify_message", type: :feature, dbscope: :example do
  context "notify_message", js: true do
    let!(:site) { gws_site }
    let!(:discussion_member) do
      create :gws_user, notice_discussion_email_user_setting: "notify", send_notice_mail_addresses: "#{unique_id}@example.jp"
    end
    let!(:forum1) { create :gws_discussion_forum, notify_state: "disabled" }
    let!(:forum2) { create :gws_discussion_forum, notify_state: "enabled" }
    let!(:forum3) { create :gws_discussion_forum, notify_state: "enabled", state: "closed" }

    let!(:new_path1) { new_gws_discussion_forum_topic_path(mode: '-', site: site.id, forum_id: forum1.id) }
    let!(:new_path2) { new_gws_discussion_forum_topic_path(mode: '-', site: site.id, forum_id: forum2.id) }
    let!(:new_path3) { new_gws_discussion_forum_topic_path(mode: '-', site: site.id, forum_id: forum3.id) }

    let(:topic_name) { unique_id }
    let(:topic_texts) { Array.new(2) { unique_id } }

    before do
      ActionMailer::Base.deliveries.clear

      forum1.add_to_set(member_ids: discussion_member.id)
      forum2.add_to_set(member_ids: discussion_member.id)
      forum3.add_to_set(member_ids: discussion_member.id)

      login_gws_user
    end

    after { ActionMailer::Base.deliveries.clear }

    it "with disabled forum" do
      visit new_path1

      within "form#item-form" do
        fill_in "item[name]", with: topic_name
        fill_in "item[text]", with: topic_texts.join("\n")
        click_button I18n.t('ss.buttons.save')
      end

      expect(SS::Notification.count).to eq 0
    end

    it "with enabled forum" do
      visit new_path2

      within "form#item-form" do
        fill_in "item[name]", with: topic_name
        fill_in "item[text]", with: topic_texts.join("\n")
        click_button I18n.t('ss.buttons.save')
      end

      forum2.reload
      expect(forum2.forum_descendants.count).to eq 1
      topic = forum2.forum_descendants.first
      expect(topic.name).to eq topic_name
      expect(topic.text).to eq topic_texts.join("\r\n")

      expect(SS::Notification.count).to eq 1
      notification = SS::Notification.first
      expect(notification.group_id).to eq site.id
      expect(notification.member_ids).to eq [ discussion_member.id ]
      expect(notification.user_id).to eq gws_user.id
      subject = I18n.t("gws/discussion.notify_message.topic.subject", forum_name: forum2.name, topic_name: topic.name)
      expect(notification.subject).to eq subject
      expect(notification.text).to be_blank
      expect(notification.html).to be_blank
      expect(notification.format).to eq "text"
      expect(notification.seen).to be_blank
      expect(notification.state).to eq "public"
      expect(notification.send_date).to be_present
      expect(notification.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum2.id}/topics#topic-#{topic.id}"
      expect(notification.reply_module).to eq "discussion"
      expect(notification.reply_model).to eq "gws/discussion/topic"
      expect(notification.reply_item_id).to eq topic.id.to_s

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq site.sender_address
      expect(mail.bcc.first).to eq discussion_member.send_notice_mail_addresses.first
      expect(mail.subject).to eq notification.subject
      url = "#{SS.config.gws.canonical_scheme}://#{SS.config.gws.canonical_domain}/.g#{site.id}/memo/notices/#{notification.id}"
      expect(mail.decoded.to_s).to include(mail.subject, url)
    end

    it "with enabled closed" do
      visit new_path3

      within "form#item-form" do
        fill_in "item[name]", with: topic_name
        fill_in "item[text]", with: topic_texts.join("\n")
        click_button I18n.t('ss.buttons.save')
      end

      expect(SS::Notification.count).to eq 0
    end
  end
end
