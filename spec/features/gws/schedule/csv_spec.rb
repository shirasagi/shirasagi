require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:item) { create :gws_schedule_plan }
  let(:index_path) { gws_schedule_plans_path site }
  let(:csv_path) { gws_schedule_csv_path site }

  context "with auth" do
    before { login_gws_user }

    it "import/export" do
      # download
      visit index_path
      first('.gws-schedule-box .btn-csv').click
      expect(current_path).to eq index_path

      # import
      visit csv_path
      page.accept_confirm do
        within "form" do
          click_button I18n.t('ss.import')
        end
      end
      expect(current_path).to eq csv_path
    end
  end
end
