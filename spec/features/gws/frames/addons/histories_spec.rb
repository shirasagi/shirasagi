require 'spec_helper'

describe "gws_frames_addons_histories", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let(:user) { gws_user }

  def signed_setting(model_class, model_id, user_id)
    Gws::HistoryFrameSetting.new(user_id: user_id, model_class: model_class, model_id: model_id).to_signed_jwt
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

    context "user item" do
      let!(:item) { user }
      let!(:setting) { signed_setting(item.class.to_s, item.id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:ok)
        expect(page).to have_css("#gws-addon-history-frame .gws-addon-history table.index")
      end
    end

    context "user's group item" do
      let!(:item) { user.groups.first }
      let!(:setting) { signed_setting(item.class.to_s, item.id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:ok)
        expect(page).to have_css("#gws-addon-history-frame .gws-addon-history table.index")
      end
    end

    context "user_title item" do
      let!(:item) { create(:gws_user_title, cur_site: site) }
      let!(:setting) { signed_setting(item.class.to_s, item.id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:ok)
        expect(page).to have_css("#gws-addon-history-frame .gws-addon-history table.index")
      end
    end

    context "user_occupation item" do
      let!(:item) { create(:gws_user_occupation, cur_site: site) }
      let!(:setting) { signed_setting(item.class.to_s, item.id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:ok)
        expect(page).to have_css("#gws-addon-history-frame .gws-addon-history table.index")
      end
    end

    context "workflow_route item" do
      let!(:item) { create(:gws_workflow_route, group_ids: user.group_ids) }
      let!(:setting) { signed_setting(item.class.to_s, item.id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:ok)
        expect(page).to have_css("#gws-addon-history-frame .gws-addon-history table.index")
      end
    end
  end

  context "with models which have site_id" do
    let!(:item) { user.gws_roles.first }
    let!(:setting) { signed_setting(item.class.to_s, item.id, user.id) }

    before { login_gws_user }

    it do
      visit gws_frames_addons_histories_path(site: site, setting: setting)
      expect(page).to have_http_status(:ok)
      expect(page).to have_css("#gws-addon-history-frame .gws-addon-history table.index")
    end
  end

  context "with other site's items" do
    let!(:other_site) { create(:gws_group, name: "other-#{unique_id}") }
    let!(:other_user) { create(:gws_user, group_ids: [other_site.id]) }

    before { login_gws_user }

    context "Gws::User model" do
      let!(:model_class) { "Gws::User" }
      let!(:model_id) { other_user.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "Gws::Group model" do
      let!(:model_class) { "Gws::Group" }
      let!(:model_id) { other_site.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end
  end

  context "with invalid params" do
    before { login_gws_user }

    context "invalid model_id" do
      let!(:model_class) { "Gws::User" }
      let!(:model_id) { 999_999 }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "invalid model_class 1" do
      let!(:model_class) { "Gws::NotExisted" }
      let!(:model_id) { user.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "invalid model_class 2" do
      let!(:model_class) { "Gws::user" }
      let!(:model_id) { user.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "invalid model_class 3" do
      let!(:model_class) { "Gws::" }
      let!(:model_id) { user.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "invalid model_class 4" do
      let!(:model_class) { "Gws::User;" }
      let!(:model_id) { user.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "not included Gws::Addon::History model" do
      let!(:model_class) { "Gws::History" }
      let!(:model_id) { user.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "not Gws model" do
      let!(:model_class) { "Cms::User" }
      let!(:model_id) { user.id }
      let!(:setting) { signed_setting(model_class, model_id, user.id) }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end
  end

  context "with invalid setting token" do
    let!(:valid_setting) { signed_setting("Gws::User", user.id, user.id) }

    before { login_gws_user }

    context "broken setting 1" do
      let!(:setting) do
        header, payload, signature = valid_setting.split(".")
        "#{header}.#{payload}.#{signature.reverse}"
      end

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "broken setting 2" do
      let!(:setting) { "a.b.c" }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "broken setting 3" do
      let!(:setting) { "W10.e30.YQ" }

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "other secret setting" do
      let!(:setting) do
        JSON::JWT.new(user_id: user.id, model_class: "Gws::User", model_id: user.id).sign("other-secret").to_s
      end

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end

    context "tampered payload" do
      let!(:setting) do
        tampered_payload = Base64.urlsafe_encode64(
          { user_id: user.id, model_class: "Gws::Group", model_id: user.groups.first.id }.to_json,
          padding: false)
        header, payload, signature = valid_setting.split(".")
        "#{header}.#{payload}.#{signature.reverse}"
      end

      it do
        visit gws_frames_addons_histories_path(site: site, setting: setting)
        expect(page).to have_http_status(:not_found)
      end
    end
  end

  context "with other user's setting token" do
    let!(:other_user) { create(:gws_user, group_ids: user.group_ids) }
    let!(:model_class) { "Gws::User" }
    let!(:model_id) { user.id }
    let!(:setting) { signed_setting(model_class, model_id, other_user.id) }

    before { login_gws_user }

    it do
      # 他のユーザーに発行されたトークンでは閲覧できない
      visit gws_frames_addons_histories_path(site: site, setting: setting)
      expect(page).to have_http_status(:forbidden)
    end
  end
end
