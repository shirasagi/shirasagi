require 'spec_helper'

describe "gws_report_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form1) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "public" }
  let!(:form2) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "closed" }

  context "new from form list" do
    let(:name) { unique_id }

    before { login_gws_user }

    it do
      visit gws_report_files_main_path(site: site)
      within "#menu" do
        wait_for_event_fired("ss:dropdownOpened") { click_on I18n.t("ss.links.new") }
        within ".gws-dropdown-menu" do
          click_on I18n.t('gws/workflow.forms.more')
        end
      end

      within ".list-items" do
        expect(page).to have_css(".list-item", text: form1.name)
        expect(page).to have_no_css(".list-item", text: form2.name)
      end
      click_on form1.name

      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Report::File.count).to eq 1
      file = Gws::Report::File.first
      expect(file.name).to eq name
    end
  end
end
