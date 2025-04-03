require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:user1) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user3) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:message1) do
    Timecop.freeze(now - 1.week) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user,
        in_to_members: [ user1.id.to_s ], in_cc_members: [ user2.id.to_s ], in_bcc_members: [ user3.id.to_s ],
        priority: rand(1..5), file_ids: [ file.id ])
    end
  end

  before { login_user user1 }

  describe "#ref" do
    it do
      visit gws_memo_messages_path(site: site)
      click_on message1.subject
      click_on I18n.t('gws/memo/message.links.ref')

      page.accept_confirm(I18n.t("gws/memo/message.confirm.send")) do
        within "form#item-form" do
          click_on I18n.t('ss.buttons.send')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")

      expect(Gws::Memo::Message.all.count).to eq 2
      Gws::Memo::Message.all.ne(id: message1.id).first.tap do |new_message|
        expect(new_message.subject).to eq message1.subject
        expect(new_message.text).to eq message1.text
        expect(new_message.format).to eq message1.format
        expect(new_message.state).to eq "public"
        expect(new_message.size).to be > 1024
        # expect(new_message.from_member_name).to eq list.sender_name
        expect(new_message.member_ids).to have(2).items
        expect(new_message.member_ids).to include(user1.id, user2.id)
        expect(new_message.to_member_ids).to eq message1.to_member_ids
        expect(new_message.cc_member_ids).to eq message1.cc_member_ids
        expect(new_message.bcc_member_ids).to be_blank
        expect(new_message.user_settings).to have(2).items
        expect(new_message.user_settings).to include(
          { "user_id" => user1.id, "path" => "INBOX"},
          { "user_id" => user2.id, "path" => "INBOX"})
        expect(new_message.priority).to eq message1.priority
        expect(new_message.file_ids).not_to eq message1.file_ids
        expect(new_message.file_ids.length).to eq message1.file_ids.length
        new_message.files.first.tap do |new_file|
          expect(new_file.id).not_to eq file.id
          expect(new_file.name).to eq file.name
          expect(new_file.filename).to eq file.filename
          expect(new_file.content_type).to eq file.content_type
          expect(new_file.size).to eq file.size
          expect(new_file.owner_item_id).to eq new_message.id
          expect(new_file.owner_item_type).to eq new_message.class.name
          expect(new_file.user_id).to eq user1.id
          expect(new_file.site_id).to be_blank
        end
      end
    end
  end
end
