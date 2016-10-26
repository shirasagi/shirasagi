require 'spec_helper'

describe Cms::GroupPermission, type: :model, dbscope: :example do
  context "article_page" do
    let!(:site) { cms_site }
    let!(:group_1) { create(:cms_group, name: "A", order: 10) }
    let!(:group_2) { create(:cms_group, name: "B", order: 20) }

    let!(:node) { create(:article_node_page, site: site, filename: "docs", name: "docs") }
    let!(:item_1) { create(:article_page, site: site, filename: "docs/page1.html", group_ids: [group_1.id]) }
    let!(:item_2) { create(:article_page, site: site, filename: "docs/page2.html", group_ids: [group_2.id]) }

    context "admin user" do
      let!(:user) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
          group_ids: [group_1.id], cms_role_ids: [role_1.id])
      end
      let!(:role_1) do
        create(:cms_role, permissions: Cms::Role.permission_names)
      end

      it "#allowed?" do
        expect(item_1.allowed?(:read, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:edit, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:delete, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:release, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:approve, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:move, user, site: site, node: node)).to be_truthy

        expect(item_2.allowed?(:read, user, site: site, node: node)).to be_truthy
        expect(item_2.allowed?(:edit, user, site: site, node: node)).to be_truthy
        expect(item_2.allowed?(:delete, user, site: site, node: node)).to be_truthy
        expect(item_2.allowed?(:release, user, site: site, node: node)).to be_truthy
        expect(item_2.allowed?(:approve, user, site: site, node: node)).to be_truthy
        expect(item_2.allowed?(:move, user, site: site, node: node)).to be_truthy
      end
    end

    context "editor user" do
      let!(:user) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
          group_ids: [group_1.id], cms_role_ids: [role_2.id])
      end
      let!(:role_2) do
        create(:cms_role, permissions: Cms::Role.permission_names.select { |r| r =~ /_private_/ })
      end

      it "#allowed?" do
        expect(item_1.allowed?(:read, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:edit, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:delete, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:release, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:approve, user, site: site, node: node)).to be_truthy
        expect(item_1.allowed?(:move, user, site: site, node: node)).to be_truthy

        expect(item_2.allowed?(:read, user, site: site, node: node)).to be_falsey
        expect(item_2.allowed?(:edit, user, site: site, node: node)).to be_falsey
        expect(item_2.allowed?(:delete, user, site: site, node: node)).to be_falsey
        expect(item_2.allowed?(:release, user, site: site, node: node)).to be_falsey
        expect(item_2.allowed?(:approve, user, site: site, node: node)).to be_falsey
        expect(item_2.allowed?(:move, user, site: site, node: node)).to be_falsey
      end
    end
  end
end
