require 'spec_helper'

describe Gws::Member, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user1) { create :gws_user, group_ids: [group1.id] }
  let!(:user2) { create :gws_user, group_ids: [group2.id] }
  let!(:user3) { create :gws_user, group_ids: [group3.id] }
  # user4 is non-active user
  let!(:user4) { create :gws_user, group_ids: [group2.id], account_expiration_date: 1.day.ago }
  let!(:cg_by_user) { create :gws_custom_group, member_ids: [user1.id, user2.id, user4.id], member_group_ids: [] }
  let!(:cg_by_group) { create :gws_custom_group, member_ids: [], member_group_ids: [group1.id, group2.id] }
  let(:item) { create :gws_schedule_plan }
  let(:new_item) { build :gws_schedule_plan }
  let(:init) do
    { member_ids: [], member_group_ids: [], member_custom_group_ids: [] }
  end

  context 'members are empty' do
    it do
      # empty
      item.update(init)
      # member_ids are required
      expect(item.valid?).to be_falsey
    end
  end

  context 'member_ids are set' do
    it do
      # empty
      item.update(init.merge(member_ids: [user1.id, user3.id, user4.id]))
      expect(item.valid?).to be_truthy
      expect(item.member_ids).to be_present
      expect(item.member_group_ids).to be_blank
      expect(item.member_custom_group_ids).to be_blank

      # check scope
      expect(item.class.member(user1)).to be_present
      expect(item.class.member(user2)).to be_blank
      expect(item.class.member(user3)).to be_present
      expect(item.class.member(user4)).to be_present

      # check methods
      expect(item.member?(user1)).to be_truthy
      expect(item.member?(user2)).to be_falsey
      expect(item.member?(user3)).to be_truthy
      expect(item.member?(user4)).to be_truthy
      expect(item.sorted_members.count).to eq 3
      expect(item.sorted_members.pluck(:id)).to include(user1.id, user3.id, user4.id)
      expect(item.sorted_members.pluck(:id)).not_to include(user2.id)
      expect(item.overall_members.count).to eq 3
      expect(item.overall_members.pluck(:id)).to include(user1.id, user3.id, user4.id)
      expect(item.overall_members.pluck(:id)).not_to include(user2.id)
      expect(item.overall_members_was.count).to eq 3
      expect(item.overall_members_was.pluck(:id)).to include(user1.id, user3.id, user4.id)
      expect(item.overall_members_was.pluck(:id)).not_to include(user2.id)
      expect(item.sorted_overall_members.count).to eq 2
      expect(item.sorted_overall_members.pluck(:id)).to include(user1.id, user3.id)
      expect(item.sorted_overall_members.pluck(:id)).not_to include(user2.id)
      expect(item.sorted_overall_members_was.count).to eq 2
      expect(item.sorted_overall_members_was.pluck(:id)).to include(user1.id, user3.id)
      expect(item.sorted_overall_members_was.pluck(:id)).not_to include(user2.id)
    end
  end

  context 'member_group_ids are set' do
    it do
      # empty
      item.update(init.merge(member_group_ids: [group2.id, group3.id]))
      expect(item.valid?).to be_truthy
      expect(item.member_ids).to be_blank
      expect(item.member_group_ids).to be_present
      expect(item.member_custom_group_ids).to be_blank

      # check scope
      expect(item.class.member(user1)).to be_blank
      expect(item.class.member(user2)).to be_present
      expect(item.class.member(user3)).to be_present
      expect(item.class.member(user4)).to be_present

      # check methods
      expect(item.member?(user1)).to be_falsey
      expect(item.member?(user2)).to be_truthy
      expect(item.member?(user3)).to be_truthy
      expect(item.member?(user4)).to be_truthy
      expect(item.sorted_members).to be_blank
      expect(item.overall_members.count).to eq 3
      expect(item.overall_members.pluck(:id)).to include(user2.id, user3.id, user4.id)
      expect(item.overall_members.pluck(:id)).not_to include(user1.id)
      expect(item.overall_members_was.count).to eq 3
      expect(item.overall_members_was.pluck(:id)).to include(user2.id, user3.id, user4.id)
      expect(item.overall_members_was.pluck(:id)).not_to include(user1.id)
      expect(item.sorted_overall_members.count).to eq 2
      expect(item.sorted_overall_members.pluck(:id)).to include(user2.id, user3.id)
      expect(item.sorted_overall_members.pluck(:id)).not_to include(user1.id)
      expect(item.sorted_overall_members_was.count).to eq 2
      expect(item.sorted_overall_members_was.pluck(:id)).to include(user2.id, user3.id)
      expect(item.sorted_overall_members_was.pluck(:id)).not_to include(user1.id)
    end
  end

  context 'member_custom_groups contain users are set' do
    it do
      # empty
      item.update(init.merge(member_custom_group_ids: [cg_by_user.id]))
      expect(item.valid?).to be_truthy
      expect(item.member_ids).to be_blank
      expect(item.member_group_ids).to be_blank
      expect(item.member_custom_group_ids).to be_present

      # check scope
      expect(item.class.member(user1)).to be_present
      expect(item.class.member(user2)).to be_present
      expect(item.class.member(user3)).to be_blank
      expect(item.class.member(user4)).to be_present

      # check methods
      expect(item.member?(user1)).to be_truthy
      expect(item.member?(user2)).to be_truthy
      expect(item.member?(user3)).to be_falsey
      expect(item.member?(user4)).to be_truthy
      expect(item.sorted_members).to be_blank
      expect(item.overall_members.count).to eq 3
      expect(item.overall_members.pluck(:id)).to include(user1.id, user2.id, user4.id)
      expect(item.overall_members.pluck(:id)).not_to include(user3.id)
      expect(item.overall_members_was.count).to eq 3
      expect(item.overall_members_was.pluck(:id)).to include(user1.id, user2.id, user4.id)
      expect(item.overall_members_was.pluck(:id)).not_to include(user3.id)
      expect(item.sorted_overall_members.count).to eq 2
      expect(item.sorted_overall_members.pluck(:id)).to include(user1.id, user2.id)
      expect(item.sorted_overall_members.pluck(:id)).not_to include(user3.id)
      expect(item.sorted_overall_members_was.count).to eq 2
      expect(item.sorted_overall_members_was.pluck(:id)).to include(user1.id, user2.id)
      expect(item.sorted_overall_members_was.pluck(:id)).not_to include(user3.id)
    end
  end

  context 'member_custom_groups contain groups are set' do
    it do
      # empty
      item.update(init.merge(member_custom_group_ids: [cg_by_group.id]))
      expect(item.valid?).to be_truthy
      expect(item.member_ids).to be_blank
      expect(item.member_group_ids).to be_blank
      expect(item.member_custom_group_ids).to be_present

      # check scope
      expect(item.class.member(user1)).to be_present
      expect(item.class.member(user2)).to be_present
      expect(item.class.member(user3)).to be_blank
      expect(item.class.member(user4)).to be_present

      # check methods
      expect(item.member?(user1)).to be_truthy
      expect(item.member?(user2)).to be_truthy
      expect(item.member?(user3)).to be_falsey
      expect(item.member?(user4)).to be_truthy
      expect(item.sorted_members).to be_blank
      expect(item.overall_members.count).to eq 3
      expect(item.overall_members.pluck(:id)).to include(user1.id, user2.id, user4.id)
      expect(item.overall_members.pluck(:id)).not_to include(user3.id)
      expect(item.overall_members_was.count).to eq 3
      expect(item.overall_members_was.pluck(:id)).to include(user1.id, user2.id, user4.id)
      expect(item.overall_members_was.pluck(:id)).not_to include(user3.id)
      expect(item.sorted_overall_members.count).to eq 2
      expect(item.sorted_overall_members.pluck(:id)).to include(user1.id, user2.id)
      expect(item.sorted_overall_members.pluck(:id)).not_to include(user3.id)
      expect(item.sorted_overall_members_was.count).to eq 2
      expect(item.sorted_overall_members_was.pluck(:id)).to include(user1.id, user2.id)
      expect(item.sorted_overall_members_was.pluck(:id)).not_to include(user3.id)
    end
  end
end
