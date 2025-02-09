require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let(:admin_index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }

  before { login_gws_user }

  context "comment_state disabled" do
    it "#new" do
      visit admin_index_path
      within "#menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-gws-agents-addons-notice-comment_setting" do
        expect(page).to have_css("dd", text: I18n.t("ss.options.state.disabled"))
      end
    end
  end

  context "comment_state enabled" do
    before do
      @notice_comment_setting = SS.config.gws.notice_comment_setting
      SS.config.replace_value_at(:gws, :notice_comment_setting, { "comment_state" => "enabled" })
    end

    after do
      SS.config.replace_value_at(:gws, :notice_comment_setting, @notice_comment_setting)
    end

    it "#new" do
      visit admin_index_path
      within "#menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-gws-agents-addons-notice-comment_setting" do
        expect(page).to have_css("dd", text: I18n.t("ss.options.state.enabled"))
      end
    end
  end
end
