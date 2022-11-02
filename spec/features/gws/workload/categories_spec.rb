require 'spec_helper'

describe "gws_workload_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_workload_categories_path site }
  let(:new_path) { new_gws_workload_category_path site }
  let(:show_path) { gws_workload_category_path site, item }
  let(:edit_path) { edit_gws_workload_category_path site, item }
  let(:delete_path) { delete_gws_workload_category_path site, item }
  let(:download_path) { download_all_gws_workload_categories_path site }
  let(:import_path) { import_gws_workload_categories_path site }

  let(:item) { create :gws_workload_category }
  let(:name) { unique_id }
  let(:group) { Gws::Group.find_by(name: "シラサギ市/企画政策部/政策課") }
  let(:year1) { 2021 }
  let(:year2) { 2022 }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      expect(page).to have_content(item.name)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-basic" do
        expect(page).to have_css("dd", text: name)
        expect(page).to have_css("dd", text: site.fiscal_year)
      end
    end

    it "#show" do
      visit show_path
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-basic" do
        expect(page).to have_css("dd", text: name)
      end
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end

    it "#download" do
      Timecop.travel(site.fiscal_first_date(year1)) do
        item

        login_gws_user
        visit download_path
        click_on I18n.t("ss.links.download")
        wait_for_download

        csv = ::CSV.read(downloads.first, headers: true)
        expect(csv.length).to eq 1
        expect(csv[0][0]).not_to be_nil
      end

      clear_downloads

      Timecop.travel(site.fiscal_first_date(year2)) do
        login_gws_user
        visit download_path
        click_on I18n.t("ss.links.download")
        wait_for_download

        csv = ::CSV.read(downloads.first, headers: true)
        expect(csv.length).to eq 0
      end
    end

    it "#import" do
      Timecop.travel(site.fiscal_first_date(year1)) do
        login_gws_user
        visit import_path

        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/workload/categories.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_selector(".list-items .list-item", count: 15)

        count = Gws::Workload::Category.site(site).size
        expect(count).to eq 15

        count = Gws::Workload::Category.site(site).search(year: year2).size
        expect(count).to eq 0

        count = Gws::Workload::Category.site(site).search(year: year1).size
        expect(count).to eq 15

        count = Gws::Workload::Category.site(site).member_group(site).size
        expect(count).to eq 0

        count = Gws::Workload::Category.site(site).member_group(group).size
        expect(count).to eq 15
      end
    end
  end
end
