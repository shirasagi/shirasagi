require 'spec_helper'

describe "gws_report_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "closed" }

  before { login_gws_user }

  context "form with no columns" do
    it do
      visit gws_report_forms_path(site: site)
      click_on form.name
      within "#addon-gws-agents-addons-report-column_setting" do
        wait_for_cbox_opened { click_on I18n.t("ss.links.preview") }
      end

      within_cbox do
        expect(page).to have_css("#addon-gws-agents-addons-report-custom_form .addon-head h2", text: form.name)
      end
    end
  end

  context "form with full types of column" do
    let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, order: 10) }
    let!(:column2) { create(:gws_column_date_field, cur_site: site, form: form, order: 20) }
    let!(:column3) { create(:gws_column_number_field, cur_site: site, form: form, order: 30) }
    let!(:column4) { create(:gws_column_url_field, cur_site: site, form: form, order: 40) }
    let!(:column5) { create(:gws_column_text_area, cur_site: site, form: form, order: 50) }
    let!(:column6) { create(:gws_column_select, cur_site: site, form: form, order: 60) }
    let!(:column7) { create(:gws_column_radio_button, cur_site: site, form: form, order: 70) }
    let!(:column8) { create(:gws_column_check_box, cur_site: site, form: form, order: 80) }
    let!(:column9) { create(:gws_column_file_upload, cur_site: site, form: form, order: 90) }
    let!(:column10) { create(:gws_column_section, cur_site: site, form: form, order: 100) }
    let!(:column11) { create(:gws_column_title, cur_site: site, form: form, order: 110) }

    it do
      visit gws_report_forms_path(site: site)
      click_on form.name
      within "#addon-gws-agents-addons-report-column_setting" do
        wait_for_cbox_opened { click_on I18n.t("ss.links.preview") }
      end

      within_cbox do
        expect(page).to have_css("#addon-gws-agents-addons-report-custom_form .addon-head h2", text: form.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column1.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column2.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column3.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column4.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column5.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column6.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column7.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column8.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt", text: column9.name)
        expect(page).to have_css(".mod-gws-report-custom_form dt .column-title", text: column11.title)
        expect(page).to have_css(".mod-gws-report-custom_form dt .column-explanation", text: column11.explanation)
      end
    end
  end

  context "link in preview" do
    let(:prefix_explanation) do
      <<~HTML
        <a href="#{unique_url}" class="link">#{unique_id}</a>
      HTML
    end
    let!(:column1) do
      create(:gws_column_text_field, cur_site: site, form: form, order: 10, prefix_explanation: prefix_explanation)
    end

    it do
      visit gws_report_forms_path(site: site)
      click_on form.name
      within "#addon-gws-agents-addons-report-column_setting" do
        wait_for_cbox_opened { click_on I18n.t("ss.links.preview") }
      end

      within_cbox do
        within "#addon-gws-agents-addons-report-custom_form" do
          expect(page).to have_css(".addon-head h2", text: form.name)
          expect(page).to have_css(".link")

          link_element = first(".link")
          # app/assets/javascripts/lib/base.js.erb で http から始まるリンクには "external" クラスが付与される。
          expect(link_element["class"]).to include("external")
          # app/assets/javascripts/gws/script.js で外部リンクには target="_blank" と rel="noopener" が付与される。
          expect(link_element["target"]).to eq "_blank"
          expect(link_element["rel"]).to eq "noopener"
        end
      end
    end
  end
end
