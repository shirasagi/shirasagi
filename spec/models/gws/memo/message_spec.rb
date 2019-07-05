require 'spec_helper'

RSpec.describe Gws::Memo::Message, type: :model do

  describe 'message' do
    context 'default params' do
      let(:memo) { create(:gws_memo_message) }
      it { expect(memo.errors.size).to eq 0 }
    end

    context 'when in_path is { gws_user.id.to_s => "INBOX.Trash" }' do
      let(:memo) { create(:gws_memo_message, in_path: { gws_user.id.to_s => 'INBOX.Trash' }) }
      it { expect(memo.errors.size).to eq 0 }
      it do
        memo.set_seen(gws_user)
        expect(memo.path(gws_user)).to eq 'INBOX.Trash'
        expect(memo.seen_at(gws_user)).not_to be_falsey
      end
    end
  end
end
