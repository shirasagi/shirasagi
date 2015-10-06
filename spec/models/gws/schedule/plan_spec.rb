require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
  describe "plan" do
    context "blank params" do
      subject { Gws::Schedule::Plan.new.valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create :gws_schedule_plan }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "time" do
      subject { create :gws_schedule_plan, start_at: start_at, end_at: end_at }
      let(:start_at) { Time.zone.local 2010, 1, 1, 0, 0, 0 }
      let(:end_at) { Time.zone.local 2010, 1, 1, 0, 0, 0 }

      it { expect(subject.errors.size).to eq 0 }
      it { expect(subject.start_at).to eq start_at }
      it { expect(subject.end_at).to eq end_at }
    end

    context "allday" do
      subject { create :gws_schedule_plan, allday: 'allday', start_on: start_on, end_on: end_on }
      let(:start_on) { Date.new 2010, 1, 1 }
      let(:end_on) { Date.new 2010, 1, 1 }

      it { expect(subject.errors.size).to eq 0 }
      it { expect(subject.start_on).to eq start_on }
      it { expect(subject.end_on).to eq end_on }
      it { expect(subject.start_at).to eq Time.zone.local(2010, 1, 1, 0, 0, 0) }
      it { expect(subject.end_at).to eq Time.zone.local(2010, 1, 1, 23, 59, 59) }
    end
  end
end
