require 'spec_helper'

describe Gws::Addon::ReadableSetting, type: :model, dbscope: :example do
  let(:user) { gws_user }
  let(:site) { gws_site }
  let(:user2) { create :gws_user }
  let(:custom_group) { create :gws_custom_group, member_ids: [user.id] }
  let(:item) { create :gws_schedule_plan }
  let(:init) do
    {
      readable_setting_range: 'select',
      readable_group_ids: [],
      readable_member_ids: [],
      readable_custom_group_ids: []
    }
  end

  context "range" do
    it "public" do
      item.update_attributes(init.merge(readable_setting_range: 'public'))
      expect(item.readable_setting_present?).to be_falsey

      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy
      expect(item.readable?(user2, site: site)).to be_falsey
      expect(item.class.readable(user2, site: site).present?).to be_falsey
    end

    it "private" do
      item.update_attributes(init.merge(readable_setting_range: 'private'))
      expect(item.readable_group_ids.present?).to be_falsey
      expect(item.readable_member_ids.present?).to be_truthy
      expect(item.readable_custom_group_ids.present?).to be_falsey

      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy
      expect(item.readable?(user2, site: site)).to be_falsey
      expect(item.class.readable(user2, site: site).present?).to be_falsey
    end

    it "select" do
      # blank (public)
      item.update_attributes(init)
      expect(item.readable_setting_present?).to be_falsey
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy

      # group
      item.update_attributes(init.merge(readable_group_ids: user.group_ids))
      expect(item.readable_group_ids.present?).to be_truthy
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy

      # member
      item.update_attributes(init.merge(readable_member_ids: [user.id]))
      expect(item.readable_member_ids.present?).to be_truthy
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy

      # custom group
      item.update_attributes(init.merge(readable_custom_group_ids: [custom_group.id]))
      expect(item.readable_custom_group_ids.present?).to be_truthy
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy
    end
  end
end
