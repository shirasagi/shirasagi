require 'spec_helper'

describe "gws_affair2_management_aggregations", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:affair2) { gws_affair2 }
  let!(:year_month) { Time.zone.now.strftime('%Y%m') }
  let!(:download_path) do
    download_gws_affair2_management_aggregations_path(site: site, employee_type: employee_type,
      unit: unit, form: form, year_month: year_month)
  end

  context "basic" do
    context "admin user" do
      before { login_gws_user }

      context "regular" do
        let!(:employee_type) { "regular" }

        context "works" do
          let!(:form) { "works" }

          context "monthly" do
            let!(:unit) { "monthly" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 19
            end
          end

          context "daily" do
            let!(:unit) { "daily" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 19
            end
          end
        end

        context "leave" do
          let!(:form) { "leave" }

          context "monthly" do
            let!(:unit) { "monthly" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 10
            end
          end

          context "daily" do
            let!(:unit) { "daily" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 10
            end
          end
        end
      end

      context "temporary_staff1" do
        let!(:employee_type) { "temporary_staff1" }

        context "works" do
          let!(:form) { "works" }

          context "monthly" do
            let!(:unit) { "monthly" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 19
            end
          end

          context "daily" do
            let!(:unit) { "daily" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 19
            end
          end
        end

        context "leave" do
          let!(:form) { "leave" }

          context "monthly" do
            let!(:unit) { "monthly" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 10
            end
          end

          context "daily" do
            let!(:unit) { "daily" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 10
            end
          end
        end
      end

      context "temporary_staff2" do
        let!(:employee_type) { "temporary_staff2" }

        context "works" do
          let!(:form) { "works" }

          context "monthly" do
            let!(:unit) { "monthly" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 19
            end
          end

          context "daily" do
            let!(:unit) { "daily" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 19
            end
          end
        end

        context "leave" do
          let!(:form) { "leave" }

          context "monthly" do
            let!(:unit) { "monthly" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 10
            end
          end

          context "daily" do
            let!(:unit) { "daily" }

            it "#download" do
              visit download_path

              click_on I18n.t("ss.links.download")
              wait_for_download

              csv = ::CSV.read(downloads.first, headers: true)
              expect(csv.headers.size).to eq 10
            end
          end
        end
      end
    end
  end
end
