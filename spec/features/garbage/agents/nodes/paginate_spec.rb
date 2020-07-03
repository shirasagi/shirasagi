require 'spec_helper'

describe "garbage_agents_nodes_search", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }

  let!(:search_node) do
    create(
      :garbage_node_search,
      filename: "search",
      layout: layout,
      st_category_ids: [category.id],
      limit: 2
    )
  end
  let!(:page_node) do
    create(
      :garbage_node_node,
      filename: "search/list",
      layout: layout,
      st_category_ids: [category.id],
      limit: 2
    )
  end

  let!(:category) do
    create(
      :garbage_node_category,
      name: "category1",
      filename: "search/category",
      layout: layout,
      limit: 2
    )
  end

  let!(:item1) do
    create(
      :garbage_node_page,
      name: "a_item1",
      filename: "search/list/e_item1",
      layout: layout,
      category_ids: [category.id],
      remark: "remark1"
    )
  end
  let!(:item2) do
    create(
      :garbage_node_page,
      name: "b_item2",
      filename: "search/list/d_item2",
      layout: layout,
      category_ids: [category.id],
      remark: "remark2"
    )
  end
  let!(:item3) do
    create(
      :garbage_node_page,
      name: "c_item3",
      filename: "search/list/c_item3",
      layout: layout,
      category_ids: [category.id],
      remark: "remark3"
    )
  end
  let!(:item4) do
    create(
      :garbage_node_page,
      name: "d_item4",
      filename: "search/list/b_item4",
      layout: layout,
      category_ids: [category.id],
      remark: "remark4"
    )
  end
  let!(:item5) do
    create(
      :garbage_node_page,
      name: "e_item5",
      filename: "search/list/a_item5",
      layout: layout,
      category_ids: [category.id],
      remark: "remark5"
    )
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "page_node" do
      it "sort with name" do
        visit page_node.url
        expect(page).to have_css(".garbage-nodes")

        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "2")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end

      it "sort with filename" do
        page_node.update(sort: "filename")

        visit page_node.url
        expect(page).to have_css(".garbage-nodes")

        expect(page).to have_link item5.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item5.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item3.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "2")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item5.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end
    end

    context "search_node" do
      it "sort with name" do
        visit search_node.url

        click_on I18n.t("garbage.submit.search")

        expect(page).to have_css(".result .number", text: 5)

        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "2")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end

      it "sort with filename" do
        search_node.update(sort: "filename")

        visit search_node.url

        click_on I18n.t("garbage.submit.search")

        expect(page).to have_css(".result .number", text: 5)

        expect(page).to have_link item5.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item5.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item3.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "2")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item5.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end
    end

    context "category" do
      it "sort with name" do
        visit category.url
        expect(page).to have_css(".garbage-nodes")

        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "2")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end

      it "sort with filename" do
        category.update(sort: "filename")

        visit category.url
        expect(page).to have_css(".garbage-nodes")

        expect(page).to have_link item5.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item5.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item3.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "2")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item5.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item1.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end
    end
  end
end
