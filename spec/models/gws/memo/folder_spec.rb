require 'spec_helper'

RSpec.describe Gws::Memo::Folder, type: :model do

  describe 'folder' do
    context 'default params' do
      let(:folder) { create(:gws_memo_folder) }
      it { expect(folder.errors.size).to eq 0 }
    end
  end
end
