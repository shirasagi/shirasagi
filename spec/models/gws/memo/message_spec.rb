require 'spec_helper'

RSpec.describe Gws::Memo::Message, type: :model do

  describe 'message' do
    context 'default params' do
      let(:memo) { create(:gws_memo_message) }
      it { expect(memo.errors.size).to eq 0 }
    end
  end
end
