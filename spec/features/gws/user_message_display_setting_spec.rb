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

  context "when memo menu is hidden in site setting" do
    before { site.update!(menu_memo_state: "hide") }

    it "does not show the setting page (404)" do
      visit gws_user_message_display_setting_path(site: site)
      expect(page).to have_title("404 Not Found | SHIRASAGI")
    end
  end

  context "when user has no memo permission" do
    let(:role) { create :gws_role_portal_user_use, cur_site: site }
    let(:user) do
      create :gws_user, name: unique_id, email: unique_email, group_ids: [ site.id ], gws_role_ids: [ role.id ]
    end

    it "does not show the setting page (403)" do
      login_user user, to: gws_user_message_display_setting_path(site: site)
      expect(page).to have_title("403 Forbidden | SHIRASAGI")
    end
  end
end
