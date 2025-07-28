require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_site_path site }
  let(:name) { unique_id }
  let(:domain) { "#{unique_id}.example.jp" }

  context "basic crud" do
    before { login_gws_user }

    it do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      click_on I18n.t("ss.buttons.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[domains]", with: domain

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.name).to eq name
      expect(site.domains.length).to eq 1
      expect(site.domains[0]).to eq domain
    end
  end
end
