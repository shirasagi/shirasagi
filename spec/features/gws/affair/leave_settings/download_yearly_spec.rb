require 'spec_helper'

describe "gws_affair_leave_settings", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { gws_site }
    let!(:year) do
      create(:gws_affair_capital_year,
        name: "令和2年",
        code: 2020,
        start_date: Time.zone.parse("2020/4/1"),
        close_date: Time.zone.parse("2021/3/31")
      )
    end
    let(:download_path) { download_yearly_gws_affair_leave_settings_path site.id, year.id }

    context "download leave_settings" do
      before { login_gws_user }

      it do
        visit download_path
        click_on I18n.t("ss.links.download")
        wait_for_download

        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 2
        end
      end
    end
  end
end
