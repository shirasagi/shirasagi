require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example, tmpdir: true do
  describe "plan" do
    context "blank params" do
      subject { Gws::Schedule::Plan.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create :gws_schedule_plan }
      it { expect(subject.errors.size).to eq 0 }
      it { expect(Gws::Reminder.where(item_id: subject.id, model: described_class.name.underscore).count).to eq 1 }
    end

    context "time" do
      subject { create :gws_schedule_plan, start_at: start_at, end_at: end_at }
      let(:start_at) { Time.zone.local 2010, 1, 1, 0, 0, 0 }
      let(:end_at) { Time.zone.local 2010, 1, 1, 0, 0, 0 }

      it { expect(subject.errors.size).to eq 0 }
      it { expect(subject.start_at).to eq start_at }
      it { expect(subject.end_at).to eq end_at }
      it { expect(Gws::Reminder.where(item_id: subject.id, model: described_class.name.underscore).count).to eq 1 }
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
      it { expect(Gws::Reminder.where(item_id: subject.id, model: described_class.name.underscore).count).to eq 1 }
    end
  end

  describe "file size limit" do
    let(:site) { gws_site }
    let(:user) { gws_user }

    let(:file_size_limit) { 10 }
    let(:start_on) { Date.new 2010, 1, 1 }
    let(:end_on) { Date.new 2010, 1, 1 }

    before do
      site.schedule_max_file_size = file_size_limit
      site.save!
    end

    context "within limit" do
      let(:file) { tmp_ss_file(contents: '0123456789', user: user) }
      subject { create :gws_schedule_plan, allday: 'allday', start_on: start_on, end_on: end_on, cur_user: user }

      it do
        subject.file_ids = [ file.id ]
        expect(subject.valid?).to be_truthy
        expect(subject.errors.empty?).to be_truthy
      end
    end

    context "without limit" do
      let(:file) { tmp_ss_file(contents: '01234567891', user: user) }
      subject { create :gws_schedule_plan, allday: 'allday', start_on: start_on, end_on: end_on, cur_user: user }

      it do
        subject.file_ids = [ file.id ]
        expect(subject.valid?).to be_falsey
        expect(subject.errors.empty?).to be_falsey
      end
    end
  end
end
