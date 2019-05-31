require 'spec_helper'

describe Gws::GroupPermission, type: :model, dbscope: :example do
  let(:user) { gws_user }
  let(:site) { gws_site }
  let(:user2) { create :gws_user }
  let(:custom_group) { create :gws_custom_group, member_ids: [user.id, user2.id] }
  let(:item) { create :gws_schedule_plan }
  let(:new_item) { build :gws_schedule_plan }
  let(:init) do
    { user_ids: [], group_ids: [], custom_group_ids: [] }
  end

  context 'full permissions' do
    it do
      # blank
      item.update(init)
      expect(item.user_ids.blank?).to be_truthy
      expect(item.group_ids.blank?).to be_truthy
      expect(item.custom_group_ids.blank?).to be_truthy

      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.class.allow(:read, user, site: site).present?).to be_truthy
      expect(item.class.allow(:edit, user, site: site).present?).to be_truthy
      expect(item.class.allow(:delete, user, site: site).present?).to be_truthy
    end
  end

  context 'private permissions' do
    before do
      user.gws_roles.each do |role|
        permissions = role.permissions.reject { |p| p =~ /_other_/ }
        role.update(permissions: permissions)
      end
    end

    it do
      item.update(init)
      expect(item.allowed?(:read, user, site: site)).to be_falsey
      expect(item.allowed?(:edit, user, site: site)).to be_falsey
      expect(item.allowed?(:delete, user, site: site)).to be_falsey
      expect(item.class.allow(:read, user, site: site).present?).to be_falsey
      expect(item.class.allow(:edit, user, site: site).present?).to be_falsey
      expect(item.class.allow(:delete, user, site: site).present?).to be_falsey

      item.update(init.merge(user_ids: [user.id]))
      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.class.allow(:read, user, site: site).present?).to be_truthy
      expect(item.class.allow(:edit, user, site: site).present?).to be_truthy
      expect(item.class.allow(:delete, user, site: site).present?).to be_truthy

      item.update(init.merge(group_ids: user.group_ids))
      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.class.allow(:read, user, site: site).present?).to be_truthy
      expect(item.class.allow(:edit, user, site: site).present?).to be_truthy
      expect(item.class.allow(:delete, user, site: site).present?).to be_truthy

      item.update(init.merge(custom_group_ids: [custom_group.id]))
      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.class.allow(:read, user, site: site).present?).to be_truthy
      expect(item.class.allow(:edit, user, site: site).present?).to be_truthy
      expect(item.class.allow(:delete, user, site: site).present?).to be_truthy
    end

    it "new_record/strict" do
      item = new_item
      item.attributes = init

      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.allowed?(:read, user, site: site, strict: true)).to be_falsey
      expect(item.allowed?(:edit, user, site: site, strict: true)).to be_falsey
      expect(item.allowed?(:delete, user, site: site, strict: true)).to be_falsey
    end
  end

  context 'no permissions' do
    it do
      item.update(init.merge(group_ids: user2.group_ids, custom_group_ids: [custom_group.id]))
      expect(item.allowed?(:read, user2, site: site)).to be_falsey
      expect(item.allowed?(:edit, user2, site: site)).to be_falsey
      expect(item.allowed?(:delete, user2, site: site)).to be_falsey
      expect(item.class.allow(:read, user2, site: site).present?).to be_falsey
      expect(item.class.allow(:edit, user2, site: site).present?).to be_falsey
      expect(item.class.allow(:delete, user2, site: site).present?).to be_falsey
    end
  end

  describe "#owned?" do
    let(:role) { create :gws_role_schedule_plan_editor }
    let(:group) { user.groups.first }
    let!(:group1) { create :gws_group, name: "#{group.name}/group-#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{group.name}/group-#{unique_id}" }
    let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role.id ] }
    let!(:user2) { create :gws_user, group_ids: [ group2.id ], gws_role_ids: [ role.id ] }
    let!(:cg_by_user) { create :gws_custom_group, member_ids: [ user1.id ], member_group_ids: [] }
    let!(:cg_by_group) { create :gws_custom_group, member_ids: [], member_group_ids: [ group1.id ] }

    context "with user" do
      before do
        item.user_ids = [ user1.id ]
        item.group_ids = []
        item.custom_group_ids = []
        item.save!
      end

      it do
        expect(item.owned?(user1)).to be_truthy
        expect(item.owned?(user2)).to be_falsey

        expect(item.allowed?(:read, user1, site: site)).to be_truthy
        expect(item.allowed?(:read, user2, site: site)).to be_falsey
        expect(item.class.allow(:read, user1, site: site)).to be_present
        expect(item.class.allow(:read, user2, site: site)).to be_blank
      end
    end

    context "with group" do
      before do
        item.user_ids = []
        item.group_ids = [ group1.id ]
        item.custom_group_ids = []
        item.save!
      end

      it do
        expect(item.owned?(user1)).to be_truthy
        expect(item.owned?(user2)).to be_falsey

        expect(item.allowed?(:read, user1, site: site)).to be_truthy
        expect(item.allowed?(:read, user2, site: site)).to be_falsey
        expect(item.class.allow(:read, user1, site: site)).to be_present
        expect(item.class.allow(:read, user2, site: site)).to be_blank
      end
    end

    context "with custom_group contains user1" do
      before do
        item.user_ids = []
        item.group_ids = []
        item.custom_group_ids = [ cg_by_user.id ]
        item.save!
      end

      it do
        expect(item.owned?(user1)).to be_truthy
        expect(item.owned?(user2)).to be_falsey

        expect(item.allowed?(:read, user1, site: site)).to be_truthy
        expect(item.allowed?(:read, user2, site: site)).to be_falsey
        expect(item.class.allow(:read, user1, site: site)).to be_present
        expect(item.class.allow(:read, user2, site: site)).to be_blank
      end
    end

    context "with custom_group contains group1" do
      before do
        item.user_ids = []
        item.group_ids = []
        item.custom_group_ids = [ cg_by_group.id ]
        item.save!
      end

      it do
        expect(item.owned?(user1)).to be_truthy
        expect(item.owned?(user2)).to be_falsey

        expect(item.allowed?(:read, user1, site: site)).to be_truthy
        expect(item.allowed?(:read, user2, site: site)).to be_falsey
        expect(item.class.allow(:read, user1, site: site)).to be_present
        expect(item.class.allow(:read, user2, site: site)).to be_blank
      end
    end
  end
end
