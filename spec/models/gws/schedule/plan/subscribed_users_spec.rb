require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
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
