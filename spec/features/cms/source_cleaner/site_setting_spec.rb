require 'spec_helper'

describe "cms/source_cleaner/site_setting", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:show_path) { cms_source_cleaner_site_setting_path site.id }

  context "with auth" do
    before { login_cms_user }

    it "#show" do
      visit show_path

      within "#crumbs" do
        expect(page).to have_link(I18n.t("cms.source_cleaner"), href: cms_source_cleaner_main_path(site: site))
        expect(page).to have_text(I18n.t("translate.site_setting"))
      end
    end
  end
end
