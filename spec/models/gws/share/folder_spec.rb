require 'spec_helper'

RSpec.describe Gws::Share::Folder, type: :model, dbscope: :example, tmpdir: true do
  let(:model) { described_class }

  describe "topic" do
    context "blank params" do
      subject { Gws::Share::Folder.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create(:gws_share_folder) }
      it { expect(subject.errors.size).to eq 0 }
    end
  end
end
