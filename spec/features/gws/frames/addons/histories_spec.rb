require 'spec_helper'

describe "gws_frames_addons_histories", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let(:user) { gws_user }

  def signed_setting(model_class, model_id, user_id: user.id)
    Gws::HistoryFrameSetting.new(user_id: user_id, model_class: model_class, model_id: model_id).to_signed_jwt
  end

  def visit_histories(model_class, model_id, user_id: user.id)
    visit gws_frames_addons_histories_path(site: site, setting: signed_setting(model_class, model_id, user_id: user_id))
  end

  def expect_histories(item)
    visit_histories(item.class.to_s, item.id)
    expect(page).to have_http_status(:ok)
    expect(page).to have_css("#gws-addon-history-frame .gws-addon-history table.index")
  end

  def expect_not_found(model_class, model_id)
    visit_histories(model_class, model_id)
    expect(page).to have_http_status(:not_found)
  end

  def expect_not_found_with_setting(setting)
    visit gws_frames_addons_histories_path(site: site, setting: setting)
    expect(page).to have_http_status(:not_found)
  end

  context "on user's detail page", js: true do
    let!(:item) { create(:gws_user, group_ids: user.group_ids) }

    it do
      login_gws_user
      visit edit_gws_user_path(site: site, id: item)
      within "form#item-form" do
        fill_in "item[name]", with: "name-#{unique_id}"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit gws_user_path(site: site, id: item)
      find("#addon-gws-agents-addons-history").click
      scroll_to_bottom
      wait_for_turbo_frame "#gws-addon-history-frame"
      within "#addon-gws-agents-addons-history table tbody" do
        expect(page).to have_text(I18n.t("gws.history.mode.update"))
      end
    end
  end

  context "with models which have no site_id" do
    before { login_gws_user }

    it do
      expect_histories(user)
      expect_histories(user.groups.first)
      expect_histories(create(:gws_user_title, cur_site: site))
      expect_histories(create(:gws_user_occupation, cur_site: site))
      expect_histories(create(:gws_workflow_route, group_ids: user.group_ids))
    end
  end

  context "with models which have site_id" do
    before { login_gws_user }

    it { expect_histories(user.gws_roles.first) }
  end

  context "with other site's items" do
    let!(:other_site) { create(:gws_group, name: "other-#{unique_id}") }
    let!(:other_user) { create(:gws_user, group_ids: [other_site.id]) }

    before { login_gws_user }

    it do
      expect_not_found("Gws::User", other_user.id)
      expect_not_found("Gws::Group", other_site.id)
    end
  end

  context "with invalid params" do
    before { login_gws_user }

    it do
      # 存在しないID
      expect_not_found("Gws::User", 999_999)
      # 存在しないクラス
      expect_not_found("Gws::NotExisted", user.id)
      expect_not_found("Gws::user", user.id)
      expect_not_found("Gws::", user.id)
      expect_not_found("Gws::User;", user.id)
      # クラスではない
      expect_not_found("Gws::Addon::History", user.id)
      # Gws::Addon::History を include していない
      expect_not_found("Gws::History", user.id)
      # Gws ではない
      expect_not_found("Cms::User", user.id)
    end
  end

  context "with invalid setting token" do
    before { login_gws_user }

    it do
      valid = signed_setting("Gws::User", user.id)
      header, payload, signature = valid.split(".")

      # 署名が壊れている
      expect_not_found_with_setting("#{header}.#{payload}.#{signature.reverse}")
      # 別の署名鍵で署名されている
      forged = JSON::JWT.new(user_id: user.id, model_class: "Gws::User", model_id: user.id).sign("other-secret").to_s
      expect_not_found_with_setting(forged)
      # payload を改ざん（署名は元のまま）
      tampered_payload = Base64.urlsafe_encode64(
        { user_id: user.id, model_class: "Gws::Group", model_id: user.groups.first.id }.to_json, padding: false)
      expect_not_found_with_setting("#{header}.#{tampered_payload}.#{signature}")
      # JWT として解釈できない
      expect_not_found_with_setting("a.b.c")
    end
  end

  context "with other user's setting token" do
    let!(:other_user) { create(:gws_user, group_ids: user.group_ids) }

    before { login_gws_user }

    it do
      # 他のユーザーに発行されたトークンでは閲覧できない
      visit_histories("Gws::User", user.id, user_id: other_user.id)
      expect(page).to have_http_status(:forbidden)
    end
  end
end
