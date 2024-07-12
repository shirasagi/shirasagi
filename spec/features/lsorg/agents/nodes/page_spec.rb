require 'spec_helper'

describe "lsorg_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  let!(:g1) { cms_group }
  let!(:g1_1) { create :cms_group, name: "#{g1.name}/#{unique_id}" }
  let!(:g1_2) { create :cms_group, name: "#{g1.name}/#{unique_id}" }

  let!(:node1) { create :lsorg_node_node, layout_id: layout.id, root_group_ids: [g1.id] }
  let!(:node2) { create :lsorg_node_page, layout_id: layout.id, cur_node: node1, page_group_id: g1_1.id }
  let!(:node3) { create :lsorg_node_page, layout_id: layout.id, cur_node: node1, page_group_id: g1_2.id }
  let!(:node4) { create :article_node_page, layout_id: layout.id }

  let!(:item1) { create :article_page, cur_node: node4, contact_group_id: g1_1.id }
  let!(:item2) { create :article_page, cur_node: node4, contact_group_id: g1_2.id }
  let!(:item3) { create :article_page, cur_node: node4, contact_group_id: g1.id, contact_sub_group_ids: [g1_1.id] }
  let!(:item4) { create :article_page, cur_node: node4 }

  let!(:item5) { create :cms_page, contact_group_id: g1_1.id }
  let!(:item6) { create :cms_page }

  context "public" do
    let!(:item) { create :cms_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "normal case" do
      it "#index" do
        visit node2.url
        within ".lsorg-pages" do
          expect(page).to have_link item1.name
          expect(page).to have_no_link item2.name
          expect(page).to have_link item3.name
          expect(page).to have_no_link item4.name
          expect(page).to have_link item5.name
          expect(page).to have_no_link item6.name
        end

        visit node3.url
        within ".lsorg-pages" do
          expect(page).to have_no_link item1.name
          expect(page).to have_link item2.name
          expect(page).to have_no_link item3.name
          expect(page).to have_no_link item4.name
          expect(page).to have_no_link item5.name
          expect(page).to have_no_link item6.name
        end
      end
    end

    context "with conditions" do
      before do
        node2.conditions = [node4.filename]
        node2.update!

        node3.conditions = [node4.filename]
        node3.update!
      end

      it "#index" do
        visit node2.url
        within ".lsorg-pages" do
          expect(page).to have_link item1.name
          expect(page).to have_no_link item2.name
          expect(page).to have_link item3.name
          expect(page).to have_no_link item4.name
          expect(page).to have_no_link item5.name
          expect(page).to have_no_link item6.name
        end

        visit node3.url
        within ".lsorg-pages" do
          expect(page).to have_no_link item1.name
          expect(page).to have_link item2.name
          expect(page).to have_no_link item3.name
          expect(page).to have_no_link item4.name
          expect(page).to have_no_link item5.name
          expect(page).to have_no_link item6.name
        end
      end
    end
  end
end
