require 'spec_helper'

describe "gws_staff_record_setting", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_staff_record_setting_path(site) }

  context "with auth", js: true do
    before do
      login_gws_user
    end

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      # edit
      click_link I18n.t('ss.links.edit')
      expect(status_code).to eq 200
    end
  end
end
