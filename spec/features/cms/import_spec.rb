require 'spec_helper'

describe "cms_import", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:index_path) { cms_import_path site.id }

  context "with auth", js: true do
    before { login_cms_user }

    it "#import" do
      visit index_path
      expect(current_path).to eq index_path

      within "form#task-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/import/site.zip"
        fill_in 'item[import_date]', with: I18n.l(Time.zone.now, format: :long)
        page.accept_alert do
          click_button I18n.t('ss.buttons.import')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_import'))
    end
  end
end
