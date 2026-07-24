require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:permissions) { %w(read_gws_organization use_gws_tabular read_gws_tabular_files edit_gws_tabular_files) }
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

  let!(:space) do
    create :gws_tabular_space, cur_site: site, cur_user: admin, state: "public", readable_setting_range: "public",
      help_url: "https://example.jp/app.pdf"
  end
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, cur_user: admin, state: 'publishing', revision: 1,
      workflow_state: 'disabled', readable_setting_range: "public"
    )
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)
  end

  let(:files_path) { gws_tabular_files_path(site: site, space: space, form: form, view: '-') }

  context "app screen help (current-navi)" do
    it "renders the space description and manual link from cur_space" do
      login_user user, to: files_path

      within ".current-navi" do
        expect(page).to have_css(".gws-menu-help__icon")
        # 説明文とマニュアルリンクが（非表示状態で）出力されている
        expect(page).to have_css(".gws-menu-help-popup__desc", visible: false)
        link = find(".gws-menu-help-popup__manual a", visible: false)
        expect(link[:href]).to end_with(sns_redirect_path(ref: "https://example.jp/app.pdf"))
      end

      # モジュール一覧ナビ(main-navi)は help: false でヘルプアイコンを出さない
      within ".main-navi" do
        expect(page).to have_no_css(".gws-menu-help")
      end
    end
  end
end
