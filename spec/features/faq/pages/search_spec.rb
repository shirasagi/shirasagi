require 'spec_helper'

describe "faq_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :faq_node_page, filename: "faq", name: "faq" }
  let(:index_path) { faq_pages_path site.id, node }
  let(:released) { Time.zone.today }

  let(:item1) { create(:faq_page, name: "item1", cur_node: node, released: released) }
  let(:item2) { create(:faq_page, name: "item2", cur_node: node, released: released.advance(days: 1)) }
  let(:item3) { create(:faq_page, name: "item3", cur_node: node, released: released.advance(days: 2)) }
  let(:item4) { create(:faq_page, name: "item4", cur_node: node, released: released.advance(days: 3)) }
  let(:item5) { create(:faq_page, name: "item5", cur_node: node, released: released.advance(days: 4)) }
  let(:item6) { create(:faq_page, name: "item6", cur_node: node, state: "closed") }

  context "search" do
    before { login_cms_user }

    it "#index" do
      item1
      item2
      item3
      item4
      item5
      item6

      visit index_path

      within ".list-items" do
        expect(page).to have_css(".list-item:nth-child(2)", text: item6.name)
        expect(page).to have_css(".list-item:nth-child(3)", text: item5.name)
        expect(page).to have_css(".list-item:nth-child(4)", text: item4.name)
        expect(page).to have_css(".list-item:nth-child(5)", text: item3.name)
        expect(page).to have_css(".list-item:nth-child(6)", text: item2.name)
        expect(page).to have_css(".list-item:nth-child(7)", text: item1.name)
      end

      within ".index-search" do
        select I18n.t("ss.options.sort.updated_desc"), from: "s[sort]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(current_path).to eq index_path

      within ".list-items" do
        expect(page).to have_css(".list-item:nth-child(2)", text: item6.name)
        expect(page).to have_css(".list-item:nth-child(3)", text: item5.name)
        expect(page).to have_css(".list-item:nth-child(4)", text: item4.name)
        expect(page).to have_css(".list-item:nth-child(5)", text: item3.name)
        expect(page).to have_css(".list-item:nth-child(6)", text: item2.name)
        expect(page).to have_css(".list-item:nth-child(7)", text: item1.name)
      end

      within ".index-search" do
        select I18n.t("ss.options.sort.updated_asc"), from: "s[sort]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(current_path).to eq index_path

      within ".list-items" do
        expect(page).to have_css(".list-item:nth-child(2)", text: item1.name)
        expect(page).to have_css(".list-item:nth-child(3)", text: item2.name)
        expect(page).to have_css(".list-item:nth-child(4)", text: item3.name)
        expect(page).to have_css(".list-item:nth-child(5)", text: item4.name)
        expect(page).to have_css(".list-item:nth-child(6)", text: item5.name)
        expect(page).to have_css(".list-item:nth-child(7)", text: item6.name)
      end

      within ".index-search" do
        select I18n.t("ss.options.sort.released_desc"), from: "s[sort]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(current_path).to eq index_path

      within ".list-items" do
        expect(page).to have_css(".list-item:nth-child(2)", text: item5.name)
        expect(page).to have_css(".list-item:nth-child(3)", text: item4.name)
        expect(page).to have_css(".list-item:nth-child(4)", text: item3.name)
        expect(page).to have_css(".list-item:nth-child(5)", text: item2.name)
        expect(page).to have_css(".list-item:nth-child(6)", text: item1.name)
        expect(page).to have_css(".list-item:nth-child(7)", text: item6.name)
      end

      within ".index-search" do
        select I18n.t("ss.options.sort.released_asc"), from: "s[sort]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(current_path).to eq index_path

      within ".list-items" do
        expect(page).to have_css(".list-item:nth-child(2)", text: item6.name)
        expect(page).to have_css(".list-item:nth-child(3)", text: item1.name)
        expect(page).to have_css(".list-item:nth-child(4)", text: item2.name)
        expect(page).to have_css(".list-item:nth-child(5)", text: item3.name)
        expect(page).to have_css(".list-item:nth-child(6)", text: item4.name)
        expect(page).to have_css(".list-item:nth-child(7)", text: item5.name)
      end
    end

    it "#index" do
      item1
      item2
      item3
      item4
      item5
      item6

      visit index_path

      within ".index-search" do
        fill_in "s[keyword]", with: item1.name
        click_on I18n.t("ss.buttons.search")
      end
      expect(current_path).to eq index_path

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)
        expect(page).to have_no_css(".list-item", text: item5.name)
        expect(page).to have_no_css(".list-item", text: item6.name)
      end

      within ".index-search" do
        fill_in "s[keyword]", with: item2.name
        click_on I18n.t("ss.buttons.search")
      end
      expect(current_path).to eq index_path

      within ".list-items" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)
        expect(page).to have_no_css(".list-item", text: item5.name)
        expect(page).to have_no_css(".list-item", text: item6.name)
      end
    end
  end
end
