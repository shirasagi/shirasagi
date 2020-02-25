require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20190918000000_gws_board_member_support.rb")

RSpec.describe SS::Migration20190918000000, dbscope: :example do
  let(:site) { create :gws_group }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group4) { create :gws_group, name: "#{site.name}/#{unique_id}", expiration_date: Time.zone.now - 1.second }
  let!(:user1) { create :gws_user, group_ids: [ group3.id ] }
  let!(:custom_group1) { create :gws_custom_group, cur_site: site }
  let!(:category) { create :gws_board_category, cur_site: site }
  let!(:topic1) { create :gws_board_topic, cur_site: site, category_ids: [ category.id ], readable_setting_range: "public" }
  let!(:topic2) do
    create(
      :gws_board_topic, cur_site: site, category_ids: [ category.id ], readable_setting_range: "select",
      readable_member_ids: [ user1.id ], readable_group_ids: [ group2.id ], readable_custom_group_ids: [ custom_group1.id ])
  end
  let!(:topic3) do
    create :gws_board_topic, cur_site: site, category_ids: [ category.id ], readable_setting_range: "private"
  end
  let!(:role_admin) do
    permissions = []
    permissions << "read_other_gws_board_posts"
    permissions << "read_private_gws_board_posts"
    permissions << "edit_other_gws_board_posts"
    permissions << "edit_private_gws_board_posts"
    permissions << "delete_other_gws_board_posts"
    permissions << "delete_private_gws_board_posts"
    permissions << "trash_other_gws_board_posts"
    permissions << "trash_private_gws_board_posts"

    create(:gws_role, permissions: permissions)
  end
  let!(:role_manager) do
    permissions = []
    permissions << "delete_private_gws_board_posts"
    permissions << "edit_private_gws_board_posts"
    permissions << "read_private_gws_board_posts"
    permissions << "trash_private_gws_board_posts"

    create(:gws_role, permissions: permissions)
  end

  before do
    described_class.new.change
  end

  it do
    topic1.reload
    expect(topic1.member_ids).to be_blank
    expect(topic1.member_group_ids.length).to eq 4
    expect(topic1.member_group_ids).to include(site.id, group1.id, group2.id, group3.id)
    expect(topic1.member_group_ids).not_to include(group4.id)
    expect(topic1.member_custom_group_ids).to be_blank

    topic2.reload
    expect(topic2.member_ids).to eq [ user1.id ]
    expect(topic2.member_group_ids).to eq [ group2.id ]
    expect(topic2.member_custom_group_ids).to eq [ custom_group1.id ]

    topic3.reload
    expect(topic3.member_ids).to be_blank
    expect(topic3.member_group_ids).to be_blank
    expect(topic3.member_custom_group_ids).to be_blank

    role_admin.reload
    expect(role_admin.permissions.length).to eq 8
    expect(role_admin.permissions.all? { |permission| permission.end_with?("_gws_board_topics") }).to be_truthy

    role_manager.reload
    expect(role_manager.permissions.length).to eq 4
    expect(role_manager.permissions.all? { |permission| permission.end_with?("_gws_board_topics") }).to be_truthy
  end
end
