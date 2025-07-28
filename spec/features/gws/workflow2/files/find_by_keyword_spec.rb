require 'spec_helper'

describe "gws_workflow2_form_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "basic operation" do
    let(:name1) { unique_id }
    let(:name2) { unique_id }
    let(:name3) { unique_id }
    let!(:application1) { create :gws_workflow2_form_application, cur_site: site, name: "#{name1}-#{name2}", state: "public" }
    let!(:application2) { create :gws_workflow2_form_application, cur_site: site, name: "#{name2}-#{name3}", state: "public" }
    let!(:external1) { create :gws_workflow2_form_external, cur_site: site, name: "#{name1}-#{name2}", state: "public" }
    let!(:external2) { create :gws_workflow2_form_external, cur_site: site, name: "#{name2}-#{name3}", state: "public" }

    context "with 'and'" do
      it do
        visit gws_workflow2_select_forms_path(site: site, state: "all", mode: "by_keyword")
        within "form.gws-workflow-select-forms-search" do
          fill_in "s[keyword]", with: "#{name1} #{name2}"
          choose "s_keyword_operator_and"
          click_on I18n.t("ss.buttons.search")
        end

        within ".gws-workflow-select-forms-table" do
          expect(page).to have_css(".gws-workflow-select-forms-table-row", count: 2)
          within "[data-id=\"#{application1.id}\"]" do
            expect(page).to have_css(".name", text: application1.name)
          end
          within "[data-id=\"#{external1.id}\"]" do
            expect(page).to have_css(".name", text: external1.name)
          end
        end
      end
    end

    context "with 'or'" do
      it do
        visit gws_workflow2_select_forms_path(site: site, state: "all", mode: "by_keyword")
        within "form.gws-workflow-select-forms-search" do
          fill_in "s[keyword]", with: "#{name1} #{name3}"
          choose "s_keyword_operator_or"
          click_on I18n.t("ss.buttons.search")
        end

        within ".gws-workflow-select-forms-table" do
          expect(page).to have_css(".gws-workflow-select-forms-table-row", count: 4)
          within "[data-id=\"#{application1.id}\"]" do
            expect(page).to have_css(".name", text: application1.name)
          end
          within "[data-id=\"#{application2.id}\"]" do
            expect(page).to have_css(".name", text: application2.name)
          end
          within "[data-id=\"#{external1.id}\"]" do
            expect(page).to have_css(".name", text: external1.name)
          end
          within "[data-id=\"#{external2.id}\"]" do
            expect(page).to have_css(".name", text: external2.name)
          end
        end
      end
    end
  end
end
