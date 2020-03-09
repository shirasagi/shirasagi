require 'spec_helper'

RSpec.describe Gws::Monitor::Topic, type: :model, dbscope: :example do
  let(:model) { described_class }

  describe "topic" do
    context "blank params" do
      subject { Gws::Monitor::Topic.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create(:gws_monitor_topic, attend_group_ids: gws_user.group_ids) }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "when attend_group_ids is missing" do
      subject { build(:gws_monitor_topic).valid? }
      it { expect(subject).to be_falsey }
    end
  end

  describe "#to_csv" do
    subject { create(:gws_monitor_topic, attend_group_ids: gws_user.group_ids) }
    it { expect(subject.to_csv).to be_truthy }
  end
end
