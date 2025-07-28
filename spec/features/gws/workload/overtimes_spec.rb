require 'spec_helper'

describe "gws_workload_overtimes", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:index_path) { gws_workload_overtimes_path site }
  let(:name) { user.name }
  let(:label) { "[#{site.fiscal_year}#{I18n.t("ss.fiscal_year")}] #{user.name}" }

  context "with auth" do
    before { login_gws_user }

    context "aggregation group not exists" do
      it do
        visit index_path
        within ".data-table" do
          expect(page).to have_no_css("tbody tr")
        end
      end
    end

    context "aggregation group created" do
      before do
        Gws::Aggregation::GroupJob.bind(site_id: site.id).perform_now
      end

      it do
        visit index_path
        within ".data-table" do
          click_on name
        end
        within "#addon-basic" do
          expect(page).to have_css("dd", text: label)
        end
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          site.fiscal_months.each do |m|
            fill_in "item[in_month#{m}_hours]", with: (10 * m)
            fill_in "item[in_month#{m}_minutes]", with: m
          end
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within "#addon-gws-agents-addons-workload-overtime" do
          site.fiscal_months.each do |m|
            expect(page).to have_css("dd", text: "#{10 * m}#{I18n.t("ss.time")} #{m}#{I18n.t("datetime.prompts.minute")}")
          end
        end
      end
    end
  end
end
