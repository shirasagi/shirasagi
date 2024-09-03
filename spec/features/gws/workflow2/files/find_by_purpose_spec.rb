require 'spec_helper'

describe "gws_workflow2_form_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "basic operation" do
    let!(:purpose1) { create :gws_workflow2_form_purpose, cur_site: site, order: 10 }
    let!(:purpose2) { create :gws_workflow2_form_purpose, cur_site: site, order: 20 }
    let!(:purpose3) { create :gws_workflow2_form_purpose, cur_site: site, order: 30 }
    let!(:category1) { create :gws_workflow2_form_category, cur_site: site, order: 10 }
    let!(:category2) { create :gws_workflow2_form_category, cur_site: site, order: 10 }
    let!(:category3) { create :gws_workflow2_form_category, cur_site: site, order: 10 }
    let!(:application1) do
      create(
        :gws_workflow2_form_application, cur_site: site, purpose_ids: [ purpose1.id, purpose2.id ],
        category_ids: [ category1.id, category2.id ], state: "public")
    end
    let!(:application2) do
      create(
        :gws_workflow2_form_application, cur_site: site, purpose_ids: [ purpose2.id, purpose3.id ],
        category_ids: [ category2.id, category3.id ], state: "public")
    end
    let!(:external1) do
      create(
        :gws_workflow2_form_external, cur_site: site, purpose_ids: [ purpose1.id, purpose2.id ],
        category_ids: [ category2.id, category3.id ], state: "public")
    end
    let!(:external2) do
      create(
        :gws_workflow2_form_external, cur_site: site, purpose_ids: [ purpose2.id, purpose3.id ],
        category_ids: [ category1.id, category2.id ], state: "public")
    end

    it do
      visit gws_workflow2_select_forms_path(site: site, state: "all", mode: "by_purpose")
      click_on purpose1.name.split("/", 2).last
      wait_for_js_ready

      within ".gws-workflow-select-forms-table" do
        expect(page).to have_css(".gws-workflow-select-forms-table-row", count: 2)
        within "[data-id=\"#{application1.id}\"]" do
          expect(page).to have_css(".name", text: application1.name)
        end
        within "[data-id=\"#{external1.id}\"]" do
          expect(page).to have_css(".name", text: external1.name)
        end
      end

      # filter by category
      within ".gws-workflow-select-forms-table" do
        within "[data-id=\"#{application1.id}\"]" do
          click_on category2.trailing_name
        end
      end
      wait_for_js_ready

      within ".gws-workflow-select-forms-table" do
        expect(page).to have_css(".gws-workflow-select-forms-table-row", count: 2)
        within "[data-id=\"#{application1.id}\"]" do
          expect(page).to have_css(".name", text: application1.name)
        end
        within "[data-id=\"#{external1.id}\"]" do
          expect(page).to have_css(".name", text: external1.name)
        end
      end

      # more filter by category
      within ".gws-workflow-select-forms-table" do
        within "[data-id=\"#{external1.id}\"]" do
          click_on category3.trailing_name
        end
      end
      wait_for_js_ready

      within ".gws-workflow-select-forms-table" do
        expect(page).to have_css(".gws-workflow-select-forms-table-row", count: 1)
        within "[data-id=\"#{external1.id}\"]" do
          expect(page).to have_css(".name", text: external1.name)
        end
      end
    end
  end
end
