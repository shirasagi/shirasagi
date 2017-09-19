require 'spec_helper'

describe "cms_import" do
  subject(:site) { cms_site }
  subject(:index_path) { cms_import_path site.id }

  context "with auth", js: true do
    before { login_cms_user }

    it "#import" do
      visit index_path
      expect(current_path).to eq index_path

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/import/site.zip"
        click_button "取り込み"
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_import'))
    end
  end
end
