require 'spec_helper'

describe "sys_users", type: :feature, dbscope: :example do
  describe "without auth" do
    it do
      login_ss_user
      visit sys_sites_path
      expect(status_code).to eq 403
    end
  end

  describe "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "modify-#{unique_id}" }
    let(:host) { unique_id }
    let(:domain) { unique_domain }
    before { login_sys_user }

    it do
      visit sys_sites_path
      expect(status_code).to eq 200

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[host]", with: host
        fill_in "item[domains]", with: domain
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))

      expect(SS::Site.all.count).to eq 1
      SS::Site.all.first.tap do |site|
        expect(site.name).to eq name
        expect(site.host).to eq host
        expect(site.domains).to eq [ domain ]
      end

      visit sys_sites_path
      click_on name
      expect(status_code).to eq 200

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))

      SS::Site.all.first.tap do |site|
        expect(site.name).to eq name2
      end

      visit sys_sites_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.deleted"))

      expect(SS::Site.all.count).to eq 0
    end
  end
end
