require 'spec_helper'

describe Gws::Tabular::SpacesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: admin, state: "public" }

  context "list head manual (汎用DB全体のヘルプ)" do
    it "uses the default manual url when menu_tabular_help_url is unset" do
      default_url = I18n.t("gws/help.tabular.manual_url", locale: :ja)
      expect(default_url).to be_present

      login_user admin, to: gws_tabular_spaces_path(site: site)
      within ".gws-tabular-space-help" do
        expect(page).to have_css(".gws-menu-help__icon")
        link = find(".gws-menu-help-popup__manual a", visible: false)
        expect(link[:href]).to end_with(sns_redirect_path(ref: default_url))
      end
    end

    it "uses the admin-configured menu_tabular_help_url when set" do
      site.update!(menu_tabular_help_url: "https://example.jp/admin-tabular.pdf")

      login_user admin, to: gws_tabular_spaces_path(site: site)
      within ".gws-tabular-space-help" do
        link = find(".gws-menu-help-popup__manual a", visible: false)
        expect(link[:href]).to end_with(sns_redirect_path(ref: "https://example.jp/admin-tabular.pdf"))
      end
    end
  end
end
