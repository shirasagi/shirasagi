require 'spec_helper'

describe Gws::Portal::GroupTreeComponent, type: :component, dbscope: :example do
  let!(:site0) { gws_site }
  let!(:user0) { gws_user }
  let!(:site) { create :gws_group, name: unique_id }
  let!(:role) { create :gws_role_admin, cur_site: site }
  let!(:admin_user) do
    user = user0
    user.update!(group_ids: user.group_ids + [ site.id ], gws_role_ids: user.gws_role_ids + [ role.id ])
    user
  end

  let!(:g1) { create(:gws_group, name: "#{site.name}/BBB") }
  let!(:g2) { create(:gws_group, name: "#{site.name}/CCC", order: 30) }
  let!(:g3) { create(:gws_group, name: "#{site.name}/BBB/DDDD", order: 40) }
  let!(:g4) { create(:gws_group, name: "#{site.name}/BBB/EEEE", order: 70) }
  let!(:g5) { create(:gws_group, name: "#{site.name}/CCC/FFFF", order: 50) }
  let!(:g6) { create(:gws_group, name: "#{site.name}/CCC/GGGG", order: 60) }
  let!(:g7) do
    # lost child
    create(:gws_group, name: "#{site.name}/HHH/IIII", order: 0)
  end

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  context "with admin user" do
    let!(:component) { described_class.new(cur_site: site, cur_user: admin_user) }

    it do
      expect(component.cache_exist?).to be_falsey

      html = render_inline component
      html.css("[data-node-id]").tap do |nodes|
        expect(nodes).to have(8).items
        nodes[0].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq site.name
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{site.id}"
        end
        nodes[1].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "BBB"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g1.id}"
        end
        nodes[2].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "DDDD"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g3.id}"
        end
        nodes[3].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "EEEE"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g4.id}"
        end
        nodes[4].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "CCC"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g2.id}"
        end
        nodes[5].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "FFFF"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g5.id}"
        end
        nodes[6].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "GGGG"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g6.id}"
        end
        nodes[7].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "HHH/IIII"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g7.id}"
        end
      end

      expect(component.cache_exist?).to be_truthy
    end
  end

  context "with group manager" do
    let!(:permissions) do
      %w(
        use_gws_portal_organization_settings use_gws_portal_group_settings use_gws_portal_user_settings
        read_private_gws_portal_group_settings edit_private_gws_portal_group_settings delete_private_gws_portal_group_settings
      )
    end
    let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
    let!(:group_manager) { create :gws_user, group_ids: [ g3.id ], gws_role_ids: [ role.id ] }
    let!(:component) { described_class.new(cur_site: site, cur_user: group_manager) }

    it do
      expect(component.cache_exist?).to be_falsey

      html = render_inline component
      html.css("[data-node-id]").tap do |nodes|
        expect(nodes).to have(8).items
        nodes[0].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq site.name
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{site.id}"
        end
        nodes[1].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "BBB"
          expect(tree_item_title.parent.name).to eq "summary"
        end
        nodes[2].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "DDDD"
          expect(tree_item_title.parent.name).to eq "a"
          expect(tree_item_title.parent["class"]).to eq "ss-tree-item-link"
          expect(tree_item_title.parent["href"]).to eq "/.g#{site.id}/portal/g-#{g3.id}"
        end
        nodes[3].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "EEEE"
          expect(tree_item_title.parent.name).to eq "li"
        end
        nodes[4].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "CCC"
          expect(tree_item_title.parent.name).to eq "summary"
        end
        nodes[5].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "FFFF"
          expect(tree_item_title.parent.name).to eq "li"
        end
        nodes[6].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "GGGG"
          expect(tree_item_title.parent.name).to eq "li"
        end
        nodes[7].css(".ss-tree-item-title")[0].tap do |tree_item_title|
          expect(tree_item_title.text).to eq "HHH/IIII"
          expect(tree_item_title.parent.name).to eq "li"
        end
      end

      expect(component.cache_exist?).to be_truthy
    end
  end
end
