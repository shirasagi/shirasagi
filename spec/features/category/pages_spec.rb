require 'spec_helper'

describe "category_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  # rubocop:disable Naming::VariableNumber
  context "ss-4433" do
    let!(:cate_node1) { create :category_node_node, cur_site: site }
    let!(:cate_page1_1) { create :category_node_page, cur_site: site, cur_node: cate_node1 }
    let!(:cate_page1_2) { create :category_node_page, cur_site: site, cur_node: cate_node1 }
    # サブフォルダーに同名のカテゴリーを作成する
    let!(:node) { create :cms_node, cur_site: site }
    let!(:cate_node2) do
      create :category_node_node, cur_site: site, cur_node: node, name: cate_node1.name, basename: cate_node1.basename
    end
    let!(:cate_page2_1) { create :category_node_page, cur_site: site, cur_node: cate_node2 }
    let!(:cate_page2_2) { create :category_node_page, cur_site: site, cur_node: cate_node2 }
    let!(:article_node) { create :article_node_page, cur_site: site, st_category_ids: [ cate_node1.id ] }

    before { login_cms_user }

    it do
      visit article_pages_path(site: site, cid: article_node)
      click_on I18n.t("ss.links.new")
      ensure_addon_opened "#addon-category-agents-addons-category"
      within "#addon-category-agents-addons-category" do
        expect(page).to have_css("[name=\"item[category_ids][]\"][value=\"#{cate_node1.id}\"]")
        expect(page).to have_css("[name=\"item[category_ids][]\"][value=\"#{cate_page1_1.id}\"]")
        expect(page).to have_css("[name=\"item[category_ids][]\"][value=\"#{cate_page1_2.id}\"]")

        expect(page).to have_no_css("[name=\"item[category_ids][]\"][value=\"#{cate_node2.id}\"]")
        expect(page).to have_no_css("[name=\"item[category_ids][]\"][value=\"#{cate_page2_1.id}\"]")
        expect(page).to have_no_css("[name=\"item[category_ids][]\"][value=\"#{cate_page2_2.id}\"]")
      end
    end
  end
  # rubocop:enable Naming::VariableNumber
end
