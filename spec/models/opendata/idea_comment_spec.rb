require 'spec_helper'

describe Opendata::IdeaComment, dbscope: :example do
  let!(:node_idea) { create :opendata_node_idea, cur_site: cms_site }
  let!(:node_area) { create :opendata_node_area, cur_site: cms_site }
  let!(:node_search) { create :opendata_node_search_idea, cur_site: cms_site }
  let!(:page_idea) do
    create :opendata_idea, cur_site: cms_site, cur_node: node_idea, area_ids: [ node_area.id ]
  end

  context ".get_member_name" do
    let!(:member) { opendata_member }
    subject! do
      create :opendata_idea_comment, cur_site: cms_site, idea: page_idea, member: member
    end

    its(:get_member_name) { is_expected.to eq member.name }
  end

  context ".get_group_name" do
    let!(:group1) { create :ss_group }
    subject! do
      create :opendata_idea_comment, cur_site: cms_site, idea: page_idea, user: ss_user, contact_group: group1
    end

    its(:get_member_name) { is_expected.to eq group1.name.sub(/.*\//, "") }
  end

  context ".get_user_groups_first" do
    let!(:group1) { create :ss_group }
    let!(:user1) { create :ss_user, group_ids: [group1.id] }
    subject! do
      create :opendata_idea_comment, cur_site: cms_site, idea: page_idea, user: user1
    end

    its(:get_member_name) { is_expected.to eq group1.name }
  end

  context ".get_guest_user" do
    subject! do
      create :opendata_idea_comment, cur_site: cms_site, idea: page_idea, user_id: 1000
    end

    its(:get_member_name) { is_expected.to eq I18n.t("opendata.labels.guest_user") }
  end
end
