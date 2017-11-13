require 'spec_helper'

RSpec.describe Gws::Circular::Post, type: :model, dbscope: :example, tmpdir: true do
  let(:model) { described_class }

  describe "topic" do
    context "blank params" do
      subject { Gws::Circular::Post.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create(:gws_circular_post, :member_ids, :due_date) }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "when member_ids are missing" do
      subject { build(:gws_circular_post, :due_date).valid? }
      it { expect(subject).to be_falsey }
    end

    context "when due_date is missing" do
      subject { build(:gws_circular_post, :member_ids).valid? }
      it { expect(subject).to be_falsey }
    end
  end

  describe "#to_csv" do
    subject { create(:gws_circular_post, :member_ids, :due_date) }
    it { expect(Gws::Circular::Post.to_csv).to be_truthy }
  end
end
