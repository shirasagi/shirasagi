require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
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
