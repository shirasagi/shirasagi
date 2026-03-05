require 'spec_helper'

# 親フォルダーが非公開の場合の注意点
describe "cms_node", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  context "when the parent is closed" do
    let!(:node1) { create :cms_node_node, cur_site: site, state: "closed" }
    let!(:node1_1) do
      create :article_node_page, cur_site: site, cur_node: node1, shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ], state: "public"
    end

    it do
      login_user admin, to: cms_contents_path(site: site)
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
          # node1 は非公開なので public_off のアイコンが付く
          expect(page).to have_css(".breadcrumb-title", text: "public_off")
          expect(page).to have_css(".breadcrumb-link", text: node1.name)
          expect(page).to have_link(node1.name, href: node_nodes_path(site: site, cid: node1))
        end
        within breadcrumb_items[2] do
          expect(page).to have_css(".breadcrumb-title", text: node1_1.name)
          expect(page).to have_css(".breadcrumb-link", text: node1_1.name)
          expect(page).to have_link(node1_1.name, href: article_pages_path(site: site, cid: node1_1))
        end
      end
      expect(page).to have_css(".list-item-parent-directory", text: I18n.t('ss.links.parent_directory'))
    end
  end
end
