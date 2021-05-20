require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:group1) { create :cms_group, name: "#{group.name}/#{unique_id}", contact_email: unique_email }
  let!(:group2) { create :cms_group, name: "#{group.name}/#{unique_id}", contact_email: unique_email }
  let(:inquiry_in_charge_permissions) do
    permissions = []
    permissions << 'read_private_cms_nodes'
    permissions << 'read_private_inquiry_answers'
    permissions << 'edit_private_inquiry_answers'
    permissions << 'delete_private_inquiry_answers'
    permissions
  end
  let!(:inquiry_in_charge_role) do
    create :cms_role, cur_site: site, name: unique_id, permissions: inquiry_in_charge_permissions
  end
  let!(:user1) do
    create :cms_user, uid: unique_id, name: unique_id, group_ids: [ group1.id ], cms_role_ids: [ inquiry_in_charge_role.id ]
  end
  let!(:user2) do
    create :cms_user, uid: unique_id, name: unique_id, group_ids: [ group2.id ], cms_role_ids: [ inquiry_in_charge_role.id ]
  end

  let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group.id, group1.id, group2.id ] }
  let!(:answer1) do
    Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: "X.X.X.X", user_agent: unique_id, group_ids: [ group1.id ])
  end
  let!(:answer2) do
    Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: "X.X.X.X", user_agent: unique_id, group_ids: [ group2.id ])
  end
  let(:name1) { ss_japanese_text }
  let(:name2) { ss_japanese_text }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge(cur_site: site)

    name_column = node.columns[0]

    data = {}
    data[name_column.id] = [name1]

    answer1.set_data(data)
    answer1.save!

    data = {}
    data[name_column.id] = [name2]

    answer2.set_data(data)
    answer2.save!
  end

  context "admins can manage all answers" do
    before do
      login_cms_user
    end

    it do
      visit inquiry_answers_path(site: site, cid: node)
      expect(page).to have_css(".list-item", count: 1 + 2)
      expect(page).to have_css(".list-items", text: name1)
      expect(page).to have_css(".list-items", text: name2)
    end
  end

  context "user1 can manage only answer1" do
    before do
      login_user user1
    end

    it do
      visit inquiry_answers_path(site: site, cid: node)
      expect(page).to have_css(".list-item", count: 1 + 1)
      expect(page).to have_css(".list-items", text: name1)
      expect(page).not_to have_css(".list-items", text: name2)
    end
  end

  context "user2 can manage only answer2" do
    before do
      login_user user2
    end

    it do
      visit inquiry_answers_path(site: site, cid: node)
      expect(page).to have_css(".list-item", count: 1 + 1)
      expect(page).not_to have_css(".list-items", text: name1)
      expect(page).to have_css(".list-items", text: name2)
    end
  end
end
