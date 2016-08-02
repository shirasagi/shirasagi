require 'spec_helper'

describe Opendata::IdeaComment, dbscope: :example do

  before do
    create_once :opendata_node_search_idea, basename: "idea/search"
  end

  let!(:node_idea) { create_once :opendata_node_idea }
  let!(:node_area) { create_once :opendata_node_area }

  let!(:page_idea) do
    create :opendata_idea, cur_site: node_idea.site, cur_node: node_idea,
      filename: "1.html", area_ids: [ node_area.id ]
  end

  let!(:member) { opendata_member }
  let!(:group_01) { create_once :ss_group }
  let!(:group_02) { create_once :ss_group }

  let!(:ss_user_01) { create_once :ss_user, group_ids: [group_01.id, group_02.id]}

  context ".get_member_name" do
    subject do
      create_once :opendata_idea_comment,
        site_id: cms_site, idea_id: page_idea.id, member_id: member.id
    end

    its(:get_member_name) { is_expected.to eq member.name }
  end

  context ".get_group_name" do
    subject do
      create_once :opendata_idea_comment,
        site_id: cms_site, idea_id: page_idea.id, user_id: ss_user.id, contact_group_id: group_02.id
    end

    its(:get_member_name) { is_expected.to eq group_02.name.sub(/.*\//, "") }
  end

  context ".get_user_groups_first" do
    subject do
      create_once :opendata_idea_comment,
        site_id: cms_site, idea_id: page_idea.id, user_id: ss_user_01.id
    end

    its(:get_member_name) { is_expected.to eq group_01.name }
  end

  context ".get_guest_user" do
    subject do
      create_once :opendata_idea_comment,
        site_id: cms_site, idea_id: page_idea.id, user_id: 1000
    end

    its(:get_member_name) { is_expected.to eq "ゲストユーザー" }
  end

end