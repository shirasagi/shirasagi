require 'spec_helper'

describe Cms::GroupPermission, type: :model, dbscope: :example do
  context "article_page" do
    let!(:site) { cms_site }
    let!(:group_1) { create(:cms_group, name: "A", order: 10) }
    let!(:group_2) { create(:cms_group, name: "B", order: 20) }

    let!(:klass) { Article::Page }
    let!(:docs1) { create(:article_page, site: site, filename: "docs1", name: "docs1", group_ids: [group_1.id]) }
    let!(:docs1_page1) { create(:article_page, site: site, filename: "docs1/page1.html", group_ids: [group_1.id]) }
    let!(:docs1_page2) { create(:article_page, site: site, filename: "docs1/page2.html", group_ids: [group_2.id]) }

    let!(:docs2) { create(:article_page, site: site, filename: "docs2", name: "docs2", group_ids: [group_2.id]) }
    let!(:docs2_page1) { create(:article_page, site: site, filename: "docs2/page1.html", group_ids: [group_1.id]) }
    let!(:docs2_page2) { create(:article_page, site: site, filename: "docs2/page2.html", group_ids: [group_2.id]) }

    context "other role" do
      let!(:user) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
          group_ids: [group_1.id], cms_role_ids: [role_1.id])
      end
      let!(:role_1) do
        create(:cms_role, permissions: Cms::Role.permission_names)
      end

      it "#allowed?" do
        # docs1
        expect(docs1_page1.allowed?(:read, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:edit, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:delete, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:release, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:approve, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:move, user, site: site, node: docs1)).to be_truthy

        expect(docs1_page2.allowed?(:read, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page2.allowed?(:edit, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page2.allowed?(:delete, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page2.allowed?(:release, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page2.allowed?(:approve, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page2.allowed?(:move, user, site: site, node: docs1)).to be_truthy

        docs1_page3 = klass.new
        expect(docs1_page3.allowed?(:read, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:edit, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:delete, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:release, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:approve, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:move, user, site: site, node: docs1)).to be_truthy

        # docs2
        expect(docs2_page1.allowed?(:read, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:edit, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:delete, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:release, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:approve, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:move, user, site: site, node: docs2)).to be_truthy

        expect(docs2_page2.allowed?(:read, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page2.allowed?(:edit, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page2.allowed?(:delete, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page2.allowed?(:release, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page2.allowed?(:approve, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page2.allowed?(:move, user, site: site, node: docs2)).to be_truthy

        docs2_page3 = klass.new
        expect(docs2_page3.allowed?(:read, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page3.allowed?(:edit, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page3.allowed?(:delete, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page3.allowed?(:release, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page3.allowed?(:approve, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page3.allowed?(:move, user, site: site, node: docs2)).to be_truthy
      end
    end

    context "private role" do
      let!(:user) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
          group_ids: [group_1.id], cms_role_ids: [role_2.id])
      end
      let!(:role_2) do
        create(:cms_role, permissions: Cms::Role.permission_names.select { |r| r =~ /_private_/ })
      end

      it "#allowed?" do
        # docs1
        expect(docs1_page1.allowed?(:read, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:edit, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:delete, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:release, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:approve, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page1.allowed?(:move, user, site: site, node: docs1)).to be_truthy

        expect(docs1_page2.allowed?(:read, user, site: site, node: docs1)).to be_falsey
        expect(docs1_page2.allowed?(:edit, user, site: site, node: docs1)).to be_falsey
        expect(docs1_page2.allowed?(:delete, user, site: site, node: docs1)).to be_falsey
        expect(docs1_page2.allowed?(:release, user, site: site, node: docs1)).to be_falsey
        expect(docs1_page2.allowed?(:approve, user, site: site, node: docs1)).to be_falsey
        expect(docs1_page2.allowed?(:move, user, site: site, node: docs1)).to be_falsey

        docs1_page3 = klass.new
        expect(docs1_page3.allowed?(:read, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:edit, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:delete, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:release, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:approve, user, site: site, node: docs1)).to be_truthy
        expect(docs1_page3.allowed?(:move, user, site: site, node: docs1)).to be_truthy

        # docs2
        expect(docs2_page1.allowed?(:read, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:edit, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:delete, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:release, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:approve, user, site: site, node: docs2)).to be_truthy
        expect(docs2_page1.allowed?(:move, user, site: site, node: docs2)).to be_truthy

        expect(docs2_page2.allowed?(:read, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page2.allowed?(:edit, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page2.allowed?(:delete, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page2.allowed?(:release, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page2.allowed?(:approve, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page2.allowed?(:move, user, site: site, node: docs2)).to be_falsey

        docs2_page3 = klass.new
        expect(docs2_page3.allowed?(:read, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page3.allowed?(:edit, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page3.allowed?(:delete, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page3.allowed?(:release, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page3.allowed?(:approve, user, site: site, node: docs2)).to be_falsey
        expect(docs2_page3.allowed?(:move, user, site: site, node: docs2)).to be_falsey
      end
    end
  end
end
