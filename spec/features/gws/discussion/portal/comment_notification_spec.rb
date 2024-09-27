require 'spec_helper'

describe "gws_discussion_forum_thread_comments", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }

  let!(:mail_addresses) { "#{unique_id}@example.jp" }
  let!(:discussion_member) do
    create :gws_user, notice_discussion_email_user_setting: "notify", send_notice_mail_addresses: mail_addresses
  end

  let(:post_texts) { Array.new(2) { unique_id } }

  before do
    ActionMailer::Base.deliveries.clear

    forum.notify_state = "enabled"
    forum.save

    forum.add_to_set(member_ids: discussion_member.id)

    login_gws_user
  end

  after { ActionMailer::Base.deliveries.clear }

  it do
    visit gws_discussion_main_path(site: site)

    click_on forum.name
    wait_for_js_ready
    click_on I18n.t("gws/discussion.links.topic.reply")
    wait_for_js_ready
    within "form.reply" do
      fill_in "item[text]", with: post_texts.join("\n")
      click_on I18n.t("ss.links.reply")
    end
    wait_for_notice I18n.t('ss.notice.saved')

    topic.reload
    expect(topic.children.count).to eq 1

    post = topic.children.first
    expect(post.text).to eq post_texts.join("\r\n")
    expect(SS::Notification.count).to eq 1

    notification = SS::Notification.first
    expect(notification.group_id).to eq site.id
    expect(notification.member_ids).to eq [ discussion_member.id ]
    expect(notification.user_id).to eq gws_user.id
    subject = I18n.t("gws/discussion.notify_message.post.subject", forum_name: forum.name, topic_name: topic.name)
    expect(notification.subject).to eq subject
    expect(notification.text).to be_blank
    expect(notification.html).to be_blank
    expect(notification.format).to eq "text"
    expect(notification.user_settings).to be_blank
    expect(notification.state).to eq "public"
    expect(notification.send_date).to be_present
    url = "/.g#{site.id}/discussion/-/forums/#{forum.id}/thread/topic#{topic.id}/comments#comment-#{post.id}"
    expect(notification.url).to eq url
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
    expect(mail.message_id).to end_with("@#{SS.config.gws.canonical_domain}.mail")
  end
end
