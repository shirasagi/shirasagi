require 'spec_helper'

describe "gws_report_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "public" }
  let!(:column1) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 10, required: "optional", input_type: "text")
  end
  subject! { create(:gws_report_file, state: "closed") }

  context "print" do
    before { login_gws_user }

    it do
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.closed')
      end
      click_on subject.name
      click_on I18n.t("ss.links.print")

      within "body.print-preview" do
        within "#main.print-preview" do
          expect(page).to have_content(subject.name)
        end
      end

      within ".no-print" do
        click_on I18n.t("ss.links.back")
      end
    end
  end
end
