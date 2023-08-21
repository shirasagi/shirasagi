require 'spec_helper'

describe "gws_search_form_targets", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_portal_path site.id }
  let(:item1) { create(:gws_search_form_target) }
  let(:item2) { create(:gws_search_form_target_external1) }
  let(:item3) { create(:gws_search_form_target_external2) }

  context "basic crud" do
    before { login_gws_user }

    it "no search target exists" do
      visit index_path
      within "#head" do
        expect(page).to have_no_css(".gws-search")
      end
    end

    it "shirasagi search target exists" do
      item1
      visit index_path
      within "#head" do
        expect(page).to have_css(".gws-search")
        expect(page).to have_css(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: true)
        within ".input-group-append", visible: true do
          expect(page).to have_css("button[type=\"submit\"]")
          expect(page).to have_no_css("button.dropdown-toggle")
        end
      end
    end

    it "external1 search target exists" do
      item1
      item2
      visit index_path
      within "#head" do
        expect(page).to have_css(".gws-search")
        expect(page).to have_selector(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: true)
        expect(page).to have_selector(".keyword[placeholder=\"#{item2.place_holder}\"]", visible: false)
        within ".input-group-append", visible: true do
          expect(page).to have_css("button[type=\"submit\"]")
          expect(page).to have_css("button.dropdown-toggle")
          find("button.dropdown-toggle").click
        end

        within ".dropdown-menu", visible: true do
          expect(page).to have_css("label", text: item1.place_holder)
          expect(page).to have_css("label", text: item2.place_holder)
          find("label", text: item2.place_holder).click
        end
        expect(page).to have_selector(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: false)
        expect(page).to have_selector(".keyword[placeholder=\"#{item2.place_holder}\"]", visible: true)

        within ".dropdown-menu", visible: true do
          find("label", text: item1.place_holder).click
        end
        expect(page).to have_selector(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: true)
        expect(page).to have_selector(".keyword[placeholder=\"#{item2.place_holder}\"]", visible: false)
      end
    end

    it "external2 search target exists" do
      item1
      item2
      item3
      visit index_path
      within "#head" do
        expect(page).to have_css(".gws-search")
        expect(page).to have_selector(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: true)
        expect(page).to have_selector(".keyword[placeholder=\"#{item2.place_holder}\"]", visible: false)
        expect(page).to have_selector(".keyword[placeholder=\"#{item3.place_holder}\"]", visible: false)
        within ".input-group-append", visible: true do
          expect(page).to have_css("button[type=\"submit\"]")
          expect(page).to have_css("button.dropdown-toggle")
          find("button.dropdown-toggle").click
        end

        within ".dropdown-menu", visible: true do
          expect(page).to have_css("label", text: item1.place_holder)
          expect(page).to have_css("label", text: item2.place_holder)
          expect(page).to have_css("label", text: item3.place_holder)
          find("label", text: item2.place_holder).click
        end
        expect(page).to have_selector(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: false)
        expect(page).to have_selector(".keyword[placeholder=\"#{item2.place_holder}\"]", visible: true)
        expect(page).to have_selector(".keyword[placeholder=\"#{item3.place_holder}\"]", visible: false)

        within ".dropdown-menu", visible: true do
          find("label", text: item3.place_holder).click
        end
        expect(page).to have_selector(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: false)
        expect(page).to have_selector(".keyword[placeholder=\"#{item2.place_holder}\"]", visible: false)
        expect(page).to have_selector(".keyword[placeholder=\"#{item3.place_holder}\"]", visible: true)

        within ".dropdown-menu", visible: true do
          find("label", text: item1.place_holder).click
        end
        expect(page).to have_selector(".keyword[placeholder=\"#{item1.place_holder}\"]", visible: true)
        expect(page).to have_selector(".keyword[placeholder=\"#{item2.place_holder}\"]", visible: false)
        expect(page).to have_selector(".keyword[placeholder=\"#{item3.place_holder}\"]", visible: false)
      end
    end
  end
end
