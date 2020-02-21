require 'spec_helper'

RSpec.describe Gws::Memo::Message, type: :model do

  describe 'message' do
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
  end
end
