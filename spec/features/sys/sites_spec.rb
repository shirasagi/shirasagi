require 'spec_helper'

describe "sys_sites", type: :feature, dbscope: :example do
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

  describe "search" do
    let!(:site1) { create(:sys_site, name: unique_id, host: unique_id, domains: unique_domain) }
    let!(:site2) { create(:sys_site, name: unique_id, host: unique_id, domains: unique_domain) }

    before { login_sys_user }

    context "by name" do
      it do
        visit sys_sites_path
        expect(page).to have_css('.list-item', count: 2)
        expect(page).to have_css('.list-item', text: site1.name)
        expect(page).to have_css('.list-item', text: site2.name)

        within "form.index-search" do
          fill_in "s[keyword]", with: site1.name
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css('.list-item', count: 1)
        expect(page).to have_css('.list-item', text: site1.name)
        expect(page).to have_no_css('.list-item', text: site2.name)
      end
    end

    context "by host" do
      it do
        visit sys_sites_path
        expect(page).to have_css('.list-item', count: 2)
        expect(page).to have_css('.list-item', text: site1.name)
        expect(page).to have_css('.list-item', text: site2.name)

        within "form.index-search" do
          fill_in "s[keyword]", with: site2.host
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css('.list-item', count: 1)
        expect(page).to have_no_css('.list-item', text: site1.name)
        expect(page).to have_css('.list-item', text: site2.name)
      end
    end

    context "by domains" do
      it do
        visit sys_sites_path
        expect(page).to have_css('.list-item', count: 2)
        expect(page).to have_css('.list-item', text: site1.name)
        expect(page).to have_css('.list-item', text: site2.name)

        within "form.index-search" do
          fill_in "s[keyword]", with: site1.domains.first
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css('.list-item', count: 1)
        expect(page).to have_css('.list-item', text: site1.name)
        expect(page).to have_no_css('.list-item', text: site2.name)
      end
    end
  end
end
