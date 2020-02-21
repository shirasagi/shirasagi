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
      item.update(init.merge(readable_setting_range: 'public'))
      expect(item.readable_setting_present?).to be_falsey

      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy
      expect(item.readable?(user2, site: site)).to be_falsey
      expect(item.class.readable(user2, site: site).present?).to be_falsey
    end

    it "private" do
      item.update(init.merge(readable_setting_range: 'private'))
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
      item.update(init)
      expect(item.readable_setting_present?).to be_falsey
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy

      # group
      item.update(init.merge(readable_group_ids: user.group_ids))
      expect(item.readable_group_ids.present?).to be_truthy
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy

      # member
      item.update(init.merge(readable_member_ids: [user.id]))
      expect(item.readable_member_ids.present?).to be_truthy
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy

      # custom group
      item.update(init.merge(readable_custom_group_ids: [custom_group.id]))
      expect(item.readable_custom_group_ids.present?).to be_truthy
      expect(item.readable?(user, site: site)).to be_truthy
      expect(item.class.readable(user, site: site).present?).to be_truthy
    end
  end

  describe "#readable?" do
    let(:folder) { create(:gws_notice_folder) }
    let(:item) { create(:gws_notice_post, folder: folder) }
    let(:group) { user.groups.first }
    let!(:group1) { create :gws_group, name: "#{group.name}/group-#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{group.name}/group-#{unique_id}" }
    let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: user.gws_role_ids }
    let!(:user2) { create :gws_user, group_ids: [ group2.id ], gws_role_ids: user.gws_role_ids }
    let!(:cg_by_user) { create :gws_custom_group, member_ids: [ user1.id ], member_group_ids: [] }
    let!(:cg_by_group) { create :gws_custom_group, member_ids: [], member_group_ids: [ group1.id ] }

    it do
      expect(item.class.readable_setting_included_custom_groups?).to be_truthy
    end

    context "with user" do
      before do
        item.readable_setting_range = "select"
        item.readable_member_ids = [ user1.id ]
        item.readable_group_ids = []
        item.readable_custom_group_ids = []
        item.save!
      end

      it do
        expect(item.readable?(user1, site: site)).to be_truthy
        expect(item.readable?(user2, site: site)).to be_falsey
        expect(item.class.readable(user1, site: site)).to be_present
        expect(item.class.readable(user2, site: site)).to be_blank
      end
    end

    context "with group" do
      before do
        item.readable_setting_range = "select"
        item.readable_member_ids = []
        item.readable_group_ids = [ group1.id ]
        item.readable_custom_group_ids = []
        item.save!
      end

      it do
        expect(item.readable?(user1, site: site)).to be_truthy
        expect(item.readable?(user2, site: site)).to be_falsey
        expect(item.class.readable(user1, site: site)).to be_present
        expect(item.class.readable(user2, site: site)).to be_blank
      end
    end

    context "with custom_group contains user" do
      before do
        item.readable_setting_range = "select"
        item.readable_member_ids = []
        item.readable_group_ids = []
        item.readable_custom_group_ids = [ cg_by_user.id ]
        item.save!
      end

      it do
        expect(item.readable?(user1, site: site)).to be_truthy
        expect(item.readable?(user2, site: site)).to be_falsey
        expect(item.class.readable(user1, site: site)).to be_present
        expect(item.class.readable(user2, site: site)).to be_blank
      end
    end

    context "with custom_group contains group" do
      before do
        item.readable_setting_range = "select"
        item.readable_member_ids = []
        item.readable_group_ids = []
        item.readable_custom_group_ids = [ cg_by_group.id ]
        item.save!
      end

      it do
        expect(item.readable?(user1, site: site)).to be_truthy
        expect(item.readable?(user2, site: site)).to be_falsey
        expect(item.class.readable(user1, site: site)).to be_present
        expect(item.class.readable(user2, site: site)).to be_blank
      end
    end
  end
end
