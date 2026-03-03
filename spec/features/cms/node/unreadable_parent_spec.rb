require 'spec_helper'

# 親フォルダーが閲覧できなかったり、削除されていてりするケース
describe "cms_node", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  context "when a user doesn't have read permission to root folder" do
    let!(:editor_role) do
      permissions = %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:group0) { cms_group }
    let!(:editor_group) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
    let!(:editor) { create :cms_test_user, cms_role_ids: [ editor_role.id ], group_ids: [ editor_group.id ] }
    let(:perform_caching) { true }

    let!(:node1) { create :cms_node_node, cur_site: site, group_ids: admin.group_ids }
    let!(:node1_1) do
      create(
        :article_node_page, cur_site: site, cur_node: node1, shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ],
        group_ids: [ editor_group.id ])
    end

    before do
      expect(node1.allowed?(:read, editor, site: site)).to be_falsey
      expect(node1_1.allowed?(:read, editor, site: site)).to be_truthy
    end

    it do
      login_user editor, to: cms_contents_path(site: site)
      within ".cms-shortcut-nodes" do
        click_on node1_1.name
      end
      within ".breadcrumb" do
        breadcrumb_items = all(".breadcrumb-item")
        expect(breadcrumb_items).to have(3).items
        within breadcrumb_items[0] do
          expect(page).to have_css(".breadcrumb-title", text: I18n.t("cms.top"))
          expect(page).to have_css(".breadcrumb-link")
          expect(page).to have_link(I18n.t("cms.top"), href: cms_contents_path(site: site))
        end
        within breadcrumb_items[1] do
          expect(page).to have_css(".breadcrumb-title", text: node1.name)
          expect(page).to have_no_css(".breadcrumb-link")
          expect(page).to have_no_link(node1.name)
        end
        within breadcrumb_items[2] do
          expect(page).to have_css(".breadcrumb-title", text: node1_1.name)
          expect(page).to have_css(".breadcrumb-link", text: node1_1.name)
          expect(page).to have_link(node1_1.name, href: article_pages_path(site: site, cid: node1_1))
        end
      end
      expect(page).to have_no_css(".list-item-parent-directory")
    end
  end

  context "when some mid-level folders are missing" do
    let!(:node1) { create :cms_node_node, cur_site: site }
    let!(:node1_1) do
      create :article_node_page, cur_site: site, cur_node: node1, shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ]
    end

    before do
      node1.delete
      expect { node1_1.reload }.not_to raise_error
    end

    it do
      login_user admin, to: cms_contents_path(site: site)
      within ".cms-shortcut-nodes" do
        click_on node1_1.name
      end
      within ".breadcrumb" do
        breadcrumb_items = all(".breadcrumb-item")
        expect(breadcrumb_items).to have(2).items
        within breadcrumb_items[0] do
          expect(page).to have_css(".breadcrumb-title", text: I18n.t("cms.top"))
          expect(page).to have_css(".breadcrumb-link")
          expect(page).to have_link(I18n.t("cms.top"), href: cms_contents_path(site: site))
        end
        within breadcrumb_items[1] do
          expect(page).to have_css(".breadcrumb-title", text: node1_1.name)
          expect(page).to have_css(".breadcrumb-link", text: node1_1.name)
          expect(page).to have_link(node1_1.name, href: article_pages_path(site: site, cid: node1_1))
        end
      end
      expect(page).to have_no_css(".list-item-parent-directory")
    end
  end
end
