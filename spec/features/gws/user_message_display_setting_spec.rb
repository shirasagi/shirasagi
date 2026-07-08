require 'spec_helper'

describe "gws_user_message_display_setting", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  before { login_gws_user }

  # ヘッダ列の画面上の左端座標。flex + order による実際の列順（件名と差出人・宛先の左右）を検証する。
  def head_field_left(field)
    page.evaluate_script(
      "document.querySelector('ul.gws-memos .list-item-head .head .#{field}').getBoundingClientRect().left"
    )
  end

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

  context "memo list column order is reflected by CSS order" do
    it do
      # 既定（差出人 → 件名）では差出人が件名より左に並ぶ
      visit gws_memo_messages_path(site)
      expect(page).to have_css("ul.gws-memos .list-item-head .head .from")
      expect(head_field_left("from")).to be < head_field_left("title")

      gws_user.update!(message_list_column_order: "subject_first")

      # subject_first では件名が差出人より左に並ぶ
      visit gws_memo_messages_path(site)
      expect(page).to have_css("ul.gws-memos.subject-first .list-item-head .head .title")
      expect(head_field_left("title")).to be < head_field_left("from")
    end
  end

  context "sent box reflects the setting on the to column" do
    it do
      gws_user.update!(message_list_column_order: "subject_first")

      # 送信箱は宛先（.to）列。subject_first では件名が宛先より左に並ぶ
      visit gws_memo_messages_path(site, folder: "INBOX.Sent")
      expect(page).to have_css("ul.gws-memos.subject-first .list-item-head .head .to")
      expect(head_field_left("title")).to be < head_field_left("to")
    end
  end

  context "revert subject_first to name_first via UI" do
    before { gws_user.update!(message_list_column_order: "subject_first") }

    it do
      # 事前状態: 一覧は subject-first
      visit gws_memo_messages_path(site)
      expect(page).to have_css("ul.gws-memos.subject-first")

      # 画面操作で name_first に戻す
      visit gws_user_message_display_setting_path(site: site)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        select I18n.t("ss.options.message_list_column_order.name_first"), from: "item[message_list_column_order]"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      gws_user.reload
      expect(gws_user.message_list_column_order).to eq "name_first"

      # 一覧から subject-first クラスが消える
      visit gws_memo_messages_path(site)
      expect(page).to have_css("ul.gws-memos")
      expect(page).to have_no_css("ul.gws-memos.subject-first")
    end
  end

  context "navigation link visibility" do
    let(:link_label) { I18n.t("modules.addons.ss/message_display_setting") }
    let(:link_href) { gws_user_message_display_setting_path(site: site) }

    it "shows the setting link in the navi when memo is usable" do
      visit gws_user_profile_path(site: site)
      expect(page).to have_link(link_label, href: link_href)
    end

    context "when memo menu is hidden in site setting" do
      before { site.update!(menu_memo_state: "hide") }

      it "hides the setting link in the navi" do
        visit gws_user_profile_path(site: site)
        expect(page).to have_no_link(link_label, href: link_href)
      end
    end

    context "when user has no memo permission" do
      let(:role) { create :gws_role_portal_user_use, cur_site: site }
      let(:user) do
        create :gws_user, name: unique_id, email: unique_email, group_ids: [ site.id ], gws_role_ids: [ role.id ]
      end

      it "hides the setting link in the navi" do
        login_user user, to: gws_user_profile_path(site: site)
        expect(page).to have_no_link(link_label, href: link_href)
      end
    end
  end
end
