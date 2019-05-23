require 'spec_helper'

RSpec.describe Gws::Schedule::Todo, type: :model, dbscope: :example do
  context "default params" do
    subject { create :gws_schedule_todo }
    it { expect(subject.errors.size).to eq 0 }
  end

  context "with reminders" do
    let(:reminder_condition) do
      { 'user_id' => gws_user.id, 'state' => 'mail', 'interval' => 10, 'interval_type' => 'minutes' }
    end
    subject { create :gws_schedule_todo, in_reminder_conditions: [ reminder_condition ] }
    it { expect(subject.errors.size).to eq 0 }
    it { expect(Gws::Reminder.where(item_id: subject.id, model: described_class.name.underscore).count).to eq 1 }
  end

  describe "#calendar_format" do
    let(:site) { gws_site }
    let(:user0) { gws_user }
    let(:group0) { user0.groups.first }
    let(:role_todo_editor) { create :gws_role_schedule_todo_editor, cur_site: site }
    let!(:group1) { create :gws_group, name: "#{group0.name}/group-#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{group0.name}/group-#{unique_id}" }
    let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role_todo_editor.id ] }
    let!(:user2) { create :gws_user, group_ids: [ group2.id ], gws_role_ids: [ role_todo_editor.id ] }
    let!(:cg_by_user) { create :gws_custom_group, member_ids: [ user1.id ], member_group_ids: [] }
    let!(:cg_by_group) { create :gws_custom_group, member_ids: [], member_group_ids: [ group1.id ] }

    subject do
      create(
        :gws_schedule_todo,
        user_ids: [ user0.id ], group_ids: [], custom_group_ids: [],
        readable_setting_range: "private", readable_member_ids: [], readable_group_ids: [], readable_custom_group_ids: [],
        member_ids: [ user0.id ], member_group_ids: [], member_custom_group_ids: []
      )
    end

    it do
      # 無関係のユーザーが指定された場合
      result = subject.calendar_format(user2, site)
      expect(result).to be_present
      expect(result[:readable]).to be_falsey
      expect(result[:editable]).to be_falsey
      expect(result[:title]).to eq I18n.t("gws/schedule.private_plan")
      expect(result[:className]).to include("fc-event-todo")
    end

    context "with user_ids" do
      before do
        subject.user_ids = [ user1.id ]
        subject.save!
      end

      it do
        # 管理者が指定された場合
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_truthy
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with group_ids" do
      before do
        subject.user_ids = []
        subject.group_ids = [ group1.id ]
        subject.save!
      end

      it do
        # 管理者が指定された場合
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_truthy
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with custom_group_ids contains users" do
      before do
        subject.user_ids = []
        subject.custom_group_ids = [ cg_by_user.id ]
        subject.save!
      end

      it do
        # 管理者が指定された場合
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_truthy
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with custom_group_ids contains groups" do
      before do
        subject.user_ids = []
        subject.custom_group_ids = [ cg_by_group.id ]
        subject.save!
      end

      it do
        # 管理者が指定された場合
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_truthy
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with readable_member_ids" do
      before do
        subject.readable_setting_range = "select"
        subject.readable_member_ids = [ user1.id ]
        subject.save!
      end

      it do
        # 閲覧者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with readable_group_ids" do
      before do
        subject.readable_setting_range = "select"
        subject.readable_group_ids = [ group1.id ]
        subject.save!
      end

      it do
        # 閲覧者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with readable_custom_group_ids contains users" do
      before do
        subject.readable_setting_range = "select"
        subject.readable_custom_group_ids = [ cg_by_user.id ]
        subject.save!
      end

      it do
        # 閲覧者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with readable_custom_group_ids contains groups" do
      before do
        subject.readable_setting_range = "select"
        subject.readable_custom_group_ids = [ cg_by_group.id ]
        subject.save!
      end

      it do
        # 閲覧者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with member_ids" do
      before do
        subject.member_ids = [ user1.id ]
        subject.save!
      end

      it do
        # 参加者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with member_group_ids" do
      before do
        subject.member_group_ids = [ group1.id ]
        subject.save!
      end

      it do
        # 参加者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with member_custom_group_ids contains users" do
      before do
        subject.member_custom_group_ids = [ cg_by_user.id ]
        subject.save!
      end

      it do
        # 参加者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end

    context "with member_custom_group_ids contains groups" do
      before do
        subject.member_custom_group_ids = [ cg_by_group.id ]
        subject.save!
      end

      it do
        # 参加者が指定された場合（管理はできない）
        result = subject.calendar_format(user1, site)
        expect(result).to be_present
        expect(result[:readable]).to be_truthy
        expect(result[:editable]).to be_falsey
        expect(result[:title]).to eq subject.name
        expect(result[:className]).to include("fc-event-todo")
      end
    end
  end

  describe "#subscribed_users" do
    let(:site) { gws_site }
    let(:user0) { gws_user }
    let(:group0) { user0.groups.first }
    let(:role_todo_editor) { create :gws_role_schedule_todo_editor, cur_site: site }
    let!(:group1) { create :gws_group, name: "#{group0.name}/group-#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{group0.name}/group-#{unique_id}" }
    let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role_todo_editor.id ] }
    let!(:user2) { create :gws_user, group_ids: [ group2.id ], gws_role_ids: [ role_todo_editor.id ] }
    let!(:cg_by_user) { create :gws_custom_group, member_ids: [ user1.id ], member_group_ids: [] }
    let!(:cg_by_group) { create :gws_custom_group, member_ids: [], member_group_ids: [ group1.id ] }

    subject do
      create(
        :gws_schedule_todo,
        user_ids: [ user0.id ], group_ids: [], custom_group_ids: [],
        readable_setting_range: "select", readable_member_ids: [], readable_group_ids: [], readable_custom_group_ids: [],
        member_ids: [ user0.id ], member_group_ids: [], member_custom_group_ids: []
      )
    end

    it do
      expect(subject.subscribed_users).to be_present
      expect(subject.subscribed_users.pluck(:id)).to include user0.id
    end

    context "with member_ids" do
      before do
        subject.member_ids = [ user1.id ]
        subject.save!
      end

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).to include user1.id
        expect(subject.subscribed_users.pluck(:id)).not_to include user2.id
      end
    end

    context "with member_group_ids" do
      before do
        subject.member_group_ids = [ group1.id ]
        subject.save!
      end

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).to include user1.id
        expect(subject.subscribed_users.pluck(:id)).not_to include user2.id
      end
    end

    context "with member_custom_group_ids contains users" do
      before do
        subject.member_custom_group_ids = [ cg_by_user.id ]
        subject.save!
      end

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).to include user1.id
        expect(subject.subscribed_users.pluck(:id)).not_to include user2.id
      end
    end

    context "with member_custom_group_ids contains groups" do
      before do
        subject.member_custom_group_ids = [ cg_by_group.id ]
        subject.save!
      end

      it do
        expect(subject.subscribed_users).to be_present
        expect(subject.subscribed_users.pluck(:id)).to include user1.id
        expect(subject.subscribed_users.pluck(:id)).not_to include user2.id
      end
    end
  end
end
