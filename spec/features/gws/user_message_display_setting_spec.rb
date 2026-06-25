require 'spec_helper'

describe "gws_user_message_display_setting", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  before { login_gws_user }

  context "basic crud" do
    it do
      visit gws_user_message_display_setting_path(site: site)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.message_list_column_order.subject_first"), from: "item[message_list_column_order]"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      gws_user.reload
      expect(gws_user.message_list_column_order).to eq "subject_first"
    end
  end

  context "memo list reflects the setting" do
    it do
      # 既定（差出人 → 件名）では subject-first クラスは付かない
      visit gws_memo_messages_path(site)
      expect(page).to have_css("ul.gws-memos")
      expect(page).to have_no_css("ul.gws-memos.subject-first")

      gws_user.update!(message_list_column_order: "subject_first")

      visit gws_memo_messages_path(site)
      expect(page).to have_css("ul.gws-memos.subject-first")
    end
  end
end
