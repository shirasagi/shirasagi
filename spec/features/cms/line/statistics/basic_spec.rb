require 'spec_helper'

describe "cms/line/statistic", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:message) { create :cms_line_message }

  let(:index_path) { cms_line_statistics_path site }
  let(:show_path) { cms_line_statistic_path site, item }
  let(:delete_path) { delete_cms_line_message_path site, item }

  describe "basic crud" do
    before { login_cms_user }

    context "multicast case" do
      let(:item) { create :cms_line_multicast_statistic, message: message }

      it "#show" do
        visit show_path
        within "#addon-basic" do
          expect(page).to have_link item.name
        end

        within "#addon-cms-agents-addons-line-statistic-body" do
          expect(page).to have_css("dd", text: item.overview_openrate_label)
          expect(page).to have_css("dd", text: item.with_null_label(:overview_unique_click))
        end

        ensure_addon_opened("#addon-cms-agents-addons-line-statistic-info")
        within "#addon-cms-agents-addons-line-statistic-info" do
          expect(page).to have_css("dd", text: item.aggregation_unit)
          expect(page).to have_css("dd", text: item.aggregation_units_by_month)
        end
      end

      it "#delete" do
        visit delete_path
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end
    end

    context "exceeded units by month" do
      let(:item) { create :cms_line_multicast_statistic, message: message, aggregation_units_by_month: 1000 }

      it "#show" do
        visit show_path
        within "#addon-basic" do
          expect(page).to have_link item.name
        end

        within "#addon-cms-agents-addons-line-statistic-body" do
          expect(page).to have_text I18n.t("cms.notices.line_statistics_exceeded_units_by_month")
        end
      end
    end
  end
end
