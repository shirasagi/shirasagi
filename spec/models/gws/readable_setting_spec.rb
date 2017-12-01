require 'spec_helper'

describe Gws::Addon::ReadableSetting, type: :model, dbscope: :example do
  let(:user) { gws_user }
  let(:site) { gws_site }
  let(:user2) { create :gws_user }
  let(:custom_group) { create :gws_custom_group, member_ids: [user2.id] }
  let(:item) { create :gws_schedule_plan }
  let(:init) do
    {
      readable_setting_range: 'select',
      readable_group_ids: gws_user.group_ids,
      readable_member_ids: [gws_user.id],
      readable_custom_group_ids: [99]
    }
  end

  it "methods" do
    # public
    item.update_attributes(init.merge(readable_setting_range: 'public'))
    expect(item.readable_setting_present?).to be_falsey

    expect(item.readable?(user2, site: gws_site)).to be_truthy
    expect(item.class.readable(user2, gws_site).present?).to be_truthy

    # private
    item.update_attributes(init.merge(readable_setting_range: 'private'))
    expect(item.readable_group_ids.present?).to be_falsey
    expect(item.readable_member_ids.present?).to be_truthy
    expect(item.readable_custom_group_ids.present?).to be_falsey

    expect(item.readable?(user2, site: gws_site)).to be_falsey
    expect(item.class.readable(user2, gws_site).present?).to be_falsey

    # select/not allow
    item.update_attributes(init)
    expect(item.readable_group_ids.present?).to be_truthy
    expect(item.readable_member_ids.present?).to be_truthy
    expect(item.readable_custom_group_ids.present?).to be_truthy
    expect(item.readable?(user2, site: gws_site)).to be_falsey
    expect(item.class.readable(user2, gws_site).present?).to be_falsey

    # select/allowed group
    item.update_attributes(init.merge(readable_group_ids: user2.group_ids))
    expect(item.readable?(user2, site: gws_site)).to be_truthy
    expect(item.class.readable(user2, gws_site).present?).to be_truthy

    # select/allowed member
    item.update_attributes(init.merge(readable_member_ids: [user2.id]))
    expect(item.readable?(user2, site: gws_site)).to be_truthy
    expect(item.class.readable(user2, gws_site).present?).to be_truthy

    # select/allowed custom group
    item.update_attributes(init.merge(readable_custom_group_ids: [custom_group.id]))
    expect(item.readable?(user2, site: gws_site)).to be_truthy
    expect(item.class.readable(user2, gws_site).present?).to be_truthy
  end
end
