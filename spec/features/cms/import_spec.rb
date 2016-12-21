require 'spec_helper'

describe "cms_import" do
  subject(:site) { cms_site }
  subject(:index_path) { cms_import_path site.id }

  context "with auth", js: true do
    before { login_cms_user }

    it "#import" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/import/site.zip"
        wait_for_ajax
        click_button "取り込み"
      end
      expect(status_code).to eq 200
    end
  end
end
