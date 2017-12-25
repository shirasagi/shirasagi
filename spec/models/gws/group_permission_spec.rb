require 'spec_helper'

describe Gws::GroupPermission, type: :model, dbscope: :example do
  let(:user) { gws_user }
  let(:site) { gws_site }
  let(:user2) { create :gws_user }
  let(:custom_group) { create :gws_custom_group, member_ids: [user.id, user2.id] }
  let(:item) { create :gws_schedule_plan }
  let(:new_item) { build :gws_schedule_plan }
  let(:init) do
    {
      user_ids: [],
      group_ids: [],
      custom_group_ids: []
    }
  end

  context 'full permissions' do
    it do
      # blank
      item.update_attributes(init)
      expect(item.user_ids.present?).to be_falsey
      expect(item.group_ids.present?).to be_falsey
      expect(item.custom_group_ids.present?).to be_falsey

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
        role.update_attributes(permissions: permissions)
      end
    end

    it do
      item.update_attributes(init)
      expect(item.allowed?(:read, user, site: site)).to be_falsey
      expect(item.allowed?(:edit, user, site: site)).to be_falsey
      expect(item.allowed?(:delete, user, site: site)).to be_falsey
      expect(item.class.allow(:read, user, site: site).present?).to be_falsey
      expect(item.class.allow(:edit, user, site: site).present?).to be_falsey
      expect(item.class.allow(:delete, user, site: site).present?).to be_falsey

      item.update_attributes(init.merge(user_ids: [user.id]))
      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.class.allow(:read, user, site: site).present?).to be_truthy
      expect(item.class.allow(:edit, user, site: site).present?).to be_truthy
      expect(item.class.allow(:delete, user, site: site).present?).to be_truthy

      item.update_attributes(init.merge(group_ids: user.group_ids))
      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.class.allow(:read, user, site: site).present?).to be_truthy
      expect(item.class.allow(:edit, user, site: site).present?).to be_truthy
      expect(item.class.allow(:delete, user, site: site).present?).to be_truthy

      item.update_attributes(init.merge(custom_group_ids: [custom_group.id]))
      expect(item.allowed?(:read, user, site: site)).to be_truthy
      expect(item.allowed?(:edit, user, site: site)).to be_truthy
      expect(item.allowed?(:delete, user, site: site)).to be_truthy
      expect(item.class.allow(:read, user, site: site).present?).to be_truthy #
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
      item.update_attributes(init.merge(group_ids: user2.group_ids, custom_group_ids: [custom_group.id]))
      expect(item.allowed?(:read, user2, site: site)).to be_falsey
      expect(item.allowed?(:edit, user2, site: site)).to be_falsey
      expect(item.allowed?(:delete, user2, site: site)).to be_falsey
      expect(item.class.allow(:read, user2, site: site).present?).to be_falsey
      expect(item.class.allow(:edit, user2, site: site).present?).to be_falsey
      expect(item.class.allow(:delete, user2, site: site).present?).to be_falsey
    end
  end
end
