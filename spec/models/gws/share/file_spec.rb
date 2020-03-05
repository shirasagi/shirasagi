require 'spec_helper'

RSpec.describe Gws::Share::File, type: :model, dbscope: :example do
  let(:model) { described_class }

  describe "topic" do
    context "blank params" do
      subject { Gws::Share::File.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create(:gws_share_file) }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "when in_file is missing" do
      subject { build(:gws_share_file, in_file: nil).valid? }
      it { expect(subject).to be_falsey }
    end
  end
end
