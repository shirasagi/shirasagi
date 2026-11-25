require 'spec_helper'

describe "gws_frames_addons_histories", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let(:user) { gws_user }

  def visit_histories(model_class, model_id)
    visit gws_frames_addons_histories_path(site: site, model_class: model_class, model_id: model_id)
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
end
