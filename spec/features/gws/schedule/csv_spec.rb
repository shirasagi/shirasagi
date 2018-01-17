require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:item) { create :gws_schedule_plan }
  let(:index_path) { gws_schedule_csv_path site }

  context "with auth" do
    before { login_gws_user }

    it "import/export" do
      # download
      visit index_path
      first('.gws-schedule-csv a', text: I18n.t('ss.links.download')).click
      expect(current_path).to eq index_path

      # import
      visit index_path
      within "form" do
        click_button I18n.t('ss.import')
      end
      expect(current_path).to eq index_path
    end
  end
end
