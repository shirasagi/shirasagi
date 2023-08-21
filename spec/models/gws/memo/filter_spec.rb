require 'spec_helper'

RSpec.describe Gws::Memo::Filter, type: :model do
  describe 'filter' do
    context 'default params' do
      let(:filter) { create(:gws_memo_filter) }
      it { expect(filter.errors.size).to eq 0 }
    end
  end
end
