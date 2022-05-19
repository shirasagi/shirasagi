require 'spec_helper'

RSpec.describe Gws::Memo::Message, type: :model do
  context 'default params' do
    let(:memo) { create(:gws_memo_message) }
    it { expect(memo.errors.size).to eq 0 }
  end

  context 'when in_path is { gws_user.id.to_s => "INBOX.Trash" }' do
    let(:user) { Gws::User.find_by(uid: 'sys') }
    let(:memo) do
      create(:gws_memo_message, in_to_members: [gws_user.id.to_s, user.id.to_s], in_path: {
        gws_user.id.to_s => 'INBOX.Trash',
        user.id.to_s => 'INBOX.Trash'
      })
    end
    it do
      expect(memo.errors.size).to eq 0

      memo.set_seen(gws_user)
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX.Trash'
      expect(memo.seen_at(gws_user)).to be_truthy
      expect(memo.seen_at(user)).to be_falsey

      memo.move(user, 'INBOX').update
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_truthy
      expect(memo.seen_at(user)).to be_falsey

      memo.set_seen(user)
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_truthy
      expect(memo.seen_at(user)).to be_truthy

      memo.unset_seen(gws_user)
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_falsey
      expect(memo.seen_at(user)).to be_truthy

      inbox_trash = Gws::Memo::Folder.static_items(gws_user, gws_site).find { |dir| dir.folder_path == 'INBOX.Trash' }
      memo.destroy_from_folder(gws_user, inbox_trash)
      expect(memo.path(gws_user)).to be_falsey
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_falsey
      expect(memo.seen_at(user)).to be_truthy

      inbox = Gws::Memo::Folder.static_items(user, gws_site).find { |dir| dir.folder_path == 'INBOX' }
      memo.destroy_from_folder(user, inbox)
      expect(memo.path(gws_user)).to be_falsey
      expect(memo.path(user)).to be_falsey
      expect(memo.seen_at(gws_user)).to be_falsey
      expect(memo.seen_at(user)).to be_falsey

      inbox_sent = Gws::Memo::Folder.static_items(gws_user, gws_site).find { |dir| dir.folder_path == 'INBOX.Sent' }
      memo.destroy_from_folder(gws_user, inbox_sent)
      expect(memo.deleted['sent']).to be_truthy
    end
  end

  context 'when gws/shared_group is given' do
    let(:site) { gws_site }
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:shared_address_group1) { create :gws_shared_address_group, order: 10, readable_setting_range: "public" }
    let!(:shared_address1) do
      create(
        :gws_shared_address_address, address_group: shared_address_group1, member: user1, name: user1.name,
        readable_setting_range: "public"
      )
    end
    let!(:shared_address2) do
      create(
        :gws_shared_address_address, address_group: shared_address_group1, member: user2, name: user2.name,
        readable_setting_range: "public"
      )
    end
    subject! do
      create(
        :gws_memo_message, cur_site: site, cur_user: user3, in_to_members: [ "shared_group:#{shared_address_group1.id}" ]
      )
    end

    it do
      expect(subject).to be_valid

      expect(subject.site_id).to eq site.id
      expect(subject.from.id).to eq user3.id
      expect(subject.to_member_ids).to be_blank
      expect(subject.to_webmail_address_group_ids).to be_blank
      expect(subject.to_shared_address_group_ids).to eq [ shared_address_group1.id ]
      expect(subject.to_member_name).to eq shared_address_group1.name
      expect(subject.cc_member_ids).to be_blank
      expect(subject.cc_webmail_address_group_ids).to be_blank
      expect(subject.cc_shared_address_group_ids).to be_blank
      expect(subject.bcc_member_ids).to be_blank
      expect(subject.bcc_webmail_address_group_ids).to be_blank
      expect(subject.bcc_shared_address_group_ids).to be_blank
      expect(subject.request_mdn).to be_blank
      expect(subject.member_ids).to have(2).items
      expect(subject.member_ids).to include(user1.id, user2.id)
      expect(subject.path(user1)).to eq 'INBOX'
      expect(subject.seen_at(user1)).to be_falsey
      expect(subject.path(user2)).to eq 'INBOX'
      expect(subject.seen_at(user2)).to be_falsey
      expect(subject.user_settings).to have(2).items
      expect(subject.user_settings).to include("user_id" => user1.id, "path" => "INBOX")
      expect(subject.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
    end
  end

  context "when webmail/address_group is given" do
    let(:site) { gws_site }
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:address_group1) { create :webmail_address_group, cur_user: user1 }
    let!(:address1) do
      create :webmail_address, cur_user: user1, address_group: address_group1, member: user2, name: user2.name
    end
    let!(:address2) do
      create :webmail_address, cur_user: user1, address_group: address_group1, member: user3, name: user3.name
    end
    subject! do
      create(
        :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ "webmail_group:#{address_group1.id}" ]
      )
    end

    it do
      expect(subject).to be_valid

      expect(subject.site_id).to eq site.id
      expect(subject.from.id).to eq user1.id
      expect(subject.to_member_ids).to be_blank
      expect(subject.to_webmail_address_group_ids).to eq [ address_group1.id ]
      expect(subject.to_shared_address_group_ids).to be_blank
      expect(subject.to_member_name).to eq address_group1.name
      expect(subject.cc_member_ids).to be_blank
      expect(subject.cc_webmail_address_group_ids).to be_blank
      expect(subject.cc_shared_address_group_ids).to be_blank
      expect(subject.bcc_member_ids).to be_blank
      expect(subject.bcc_webmail_address_group_ids).to be_blank
      expect(subject.bcc_shared_address_group_ids).to be_blank
      expect(subject.request_mdn).to be_blank
      expect(subject.member_ids).to have(2).items
      expect(subject.member_ids).to include(user2.id, user3.id)
      expect(subject.path(user2)).to eq 'INBOX'
      expect(subject.seen_at(user1)).to be_falsey
      expect(subject.path(user3)).to eq 'INBOX'
      expect(subject.seen_at(user2)).to be_falsey
      expect(subject.user_settings).to have(2).items
      expect(subject.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
      expect(subject.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
    end
  end
end
