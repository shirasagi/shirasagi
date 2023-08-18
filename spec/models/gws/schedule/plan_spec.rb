require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
  describe "plan" do
    context "blank params" do
      subject { Gws::Schedule::Plan.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create :gws_schedule_plan }
      it do
        expect(subject.errors.size).to eq 0
      end
    end

    context "time" do
      subject { create :gws_schedule_plan, start_at: start_at, end_at: end_at }
      let(:start_at) { Time.zone.local 2010, 1, 1, 0, 0, 0 }
      let(:end_at) { Time.zone.local 2010, 1, 1, 1, 0, 0 }

      it do
        expect(subject.errors.size).to eq 0
        expect(subject.start_at).to eq start_at
        expect(subject.end_at).to eq end_at
      end
    end

    context "allday" do
      subject { create :gws_schedule_plan, allday: 'allday', start_on: start_on, end_on: end_on }
      let(:start_on) { Date.new 2010, 1, 1 }
      let(:end_on) { Date.new 2010, 1, 1 }

      it do
        expect(subject.errors.size).to eq 0
        expect(subject.start_on).to eq start_on
        expect(subject.end_on).to eq end_on
        expect(subject.start_at).to eq Time.zone.local(2010, 1, 1, 0, 0, 0)
        expect(subject.end_at).to eq Time.zone.local(2010, 1, 1, 23, 59, 59)

        opts = {}
        opts[:cur_user] = gws_user
        cal = subject.calendar_format(gws_user, gws_site)
        expect(cal[:className]).to include 'fc-event-range'
        expect(cal[:className]).to include 'fc-event-allday'
      end
    end

    context "repeat" do
      subject do
        create :gws_schedule_plan, allday: 'allday', start_on: start_on, end_on: end_on,
          repeat_type: 'daily', repeat_start: repeat_start, repeat_end: repeat_end,
          interval: interval, wdays: []
      end
      let(:start_on) { Date.new 2010, 1, 1 }
      let(:end_on) { Date.new 2010, 1, 1 }
      let(:repeat_start) { Date.new(2016, 5, 1) }
      let(:repeat_end) { Date.new(2017, 5, 1) }
      let(:interval) { 1 }

      it do
        expect(subject.repeat_plan.present?).to be_truthy

        subject.allday = ''
        subject.save
        expect(subject.repeat_plan.present?).to be_truthy

        subject.repeat_end = Date.new(2020, 5, 1)
        expect(subject.valid?).to be_falsey
      end
    end

    context "with reminders" do
      let(:reminder_condition) do
        { 'user_id' => gws_user.id, 'state' => 'mail', 'interval' => 10, 'interval_type' => 'minutes' }
      end
      subject { create :gws_schedule_plan, in_reminder_conditions: [ reminder_condition ] }
      it do
        expect(subject.errors.size).to eq 0
        expect(Gws::Reminder.where(item_id: subject.id, model: described_class.name.underscore).count).to eq 1
      end
    end

    context "clone" do
      subject { create(:gws_schedule_plan).new_clone }
      it do
        expect(subject.id.blank?).to be_truthy
        expect(subject.user_id.blank?).to be_truthy
        expect(subject.cur_user.present?).to be_truthy
        expect(subject.cur_site.present?).to be_truthy
      end
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

  describe "history trash" do
    let!(:site) { gws_site }
    let(:user) { gws_user }
    let!(:site2) { cms_site }

    let(:start_on) { Date.new 2010, 1, 1 }
    let(:end_on) { Date.new 2010, 1, 1 }

    context "when destroy gws schedule plan" do
      let(:file) { tmp_ss_file(contents: '0123456789', site: site2, user: user) }
      subject { create :gws_schedule_plan, start_on: start_on, end_on: end_on, cur_site: site, cur_user: user }

      it do
        subject.file_ids = [ file.id ]
        subject.destroy
        expect(History::Trash.count).to eq 0
      end
    end
  end

  describe "#reminder_url" do
    let(:item) { create :gws_schedule_plan }
    subject { item.reminder_url }

    it do
      expect(subject).to be_a(Array)
      expect(subject.length).to eq 2
      expect(subject[0]).to eq "gws_schedule_plan_path"
      expect(subject[1]).to be_a(Hash)

      path = Rails.application.routes.url_helpers.send(subject[0], subject[1])
      expect(path).to eq "/.g#{item.site_id}/schedule/plans/#{item.id}"
    end
  end

  describe "#subscribed_users" do
    let!(:group1) { create :gws_group, name: "#{gws_site.name}/group-#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{gws_site.name}/group-#{unique_id}" }
    let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:user2) { create :gws_user, group_ids: [ group2.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:cg_by_user) { create :gws_custom_group, member_ids: [ user1.id ], member_group_ids: [] }
    let!(:cg_by_group) { create :gws_custom_group, member_ids: [], member_group_ids: [ group2.id ] }

    context "with member_ids" do
      subject { create :gws_schedule_plan, member_ids: [ user1.id ], member_group_ids: [], member_custom_group_ids: [] }

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).to include user1.id
        expect(subject.subscribed_users.pluck(:id)).not_to include user2.id
      end
    end

    context "with member_group_ids" do
      subject { create :gws_schedule_plan, member_ids: [], member_group_ids: [ group2.id ], member_custom_group_ids: [] }

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).not_to include user1.id
        expect(subject.subscribed_users.pluck(:id)).to include user2.id
      end
    end

    context "with member_custom_group_ids contains users" do
      subject { create :gws_schedule_plan, member_ids: [], member_group_ids: [], member_custom_group_ids: [ cg_by_user.id ] }

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).to include user1.id
        expect(subject.subscribed_users.pluck(:id)).not_to include user2.id
      end
    end

    context "with member_custom_group_ids contains groups" do
      subject { create :gws_schedule_plan, member_ids: [], member_group_ids: [], member_custom_group_ids: [ cg_by_group.id ] }

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).not_to include user1.id
        expect(subject.subscribed_users.pluck(:id)).to include user2.id
      end
    end
  end
end
