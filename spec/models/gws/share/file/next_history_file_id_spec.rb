require 'spec_helper'

RSpec.describe Gws::Share::File, type: :model, dbscope: :example do
  describe "#next_history_file_id" do
    subject! { create :gws_share_file }

    context 'with initial file' do
      it { expect(subject.send(:next_history_file_id)).to eq 1 }
    end

    context 'with 100 history file' do
      before do
        ::Fs.binwrite("#{subject.path}_history100", '')
      end

      it { expect(subject.send(:next_history_file_id)).to eq 101 }
    end
  end
end
