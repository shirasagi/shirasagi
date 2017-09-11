require 'spec_helper'

describe "gws_staff_record_setting", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_staff_record_setting_path(site) }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit index_path

      # edit/update
      click_link I18n.t('ss.links.edit')
      click_button I18n.t('ss.buttons.save')

      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end
