require 'spec_helper'

RSpec.describe Gws::Memo::Signature, type: :model do

  describe 'filter' do
    context 'default params' do
      let(:signature) { create(:gws_memo_signature) }
      it { expect(signature.errors.size).to eq 0 }
    end
  end
end
