require 'spec_helper'

describe "member_agents_nodes_photo_search", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  let!(:category1) { create :member_node_photo_category, layout_id: layout.id, filename: "category1" }
  let!(:category2) { create :member_node_photo_category, layout_id: layout.id, filename: "category2" }
  let!(:category3) { create :member_node_photo_category, layout_id: layout.id, filename: "category3" }

  let!(:location1) { create :member_node_photo_location, layout_id: layout.id, filename: "location1" }
  let!(:location2) { create :member_node_photo_location, layout_id: layout.id, filename: "location2" }
  let!(:location3) { create :member_node_photo_location, layout_id: layout.id, filename: "location3" }

  let!(:node) { create :member_node_photo, layout_id: layout.id, filename: "node" }
  let!(:search) { create :member_node_photo_search, layout_id: layout.id, filename: "node/search" }

  let!(:item) do
    create :member_photo, cur_node: node,
      photo_category_ids: [category1.id],
      photo_location_ids: [location1.id]
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit search.url

      expect(page).to have_link(I18n.t("member.links.search_condition"))
      expect(page).to have_link(I18n.t("member.links.index"))
      expect(page).to have_link(I18n.t("member.links.map"))

      expect(page).to have_css(".member-photos")
      expect(page).to have_css(".member-photos a img")

      click_on I18n.t("member.links.search_condition")
      wait_for_cbox do
        expect(page).to have_css("label", text: category1.name)
        expect(page).to have_css("label", text: category2.name)
        expect(page).to have_css("label", text: category3.name)

        expect(page).to have_css("label", text: location1.name)
        expect(page).to have_css("label", text: location2.name)
        expect(page).to have_css("label", text: location3.name)

        first("[value=\"#{category2.id}\"]").set(true)
        first("[value=\"#{location2.id}\"]").set(true)

        click_on I18n.t('facility.submit.search')
      end

      expect(page).to have_no_css(".member-photos a img")
    end
  end
end
