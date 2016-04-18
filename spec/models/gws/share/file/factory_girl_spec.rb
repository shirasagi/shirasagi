require 'spec_helper'

RSpec.describe Gws::Share::File, type: :model, dbscope: :example do
  describe "FactoryGirl test" do
    describe "default" do
      before { create :gws_share_file }
      it { expect(described_class.count).to eq 1 }
    end

    describe "empty" do
      subject { described_class.new(cur_site: gws_site) }
      its(:valid?) { is_expected.to be_falsey }
    end
  end
end
