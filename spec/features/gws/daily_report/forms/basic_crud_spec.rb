require 'spec_helper'

describe "gws_daily_report_forms", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:year) { site.fiscal_year }
    let(:order) { rand(10) }
    let(:memo) { Array.new(rand(3..10)) { unique_id }.join("\n") }
    let(:daily_report_group) { group1 }

    before { login_gws_user }

    it do
      #
      # create
      #
      visit gws_daily_report_forms_path(site: site)
      within ".nav-menu" do
        click_on I18n.t('ss.links.new')
      end
      within "form#item-form" do
        within "#addon-basic" do
          fill_in "item[name]", with: name
          fill_in "item[order]", with: order
          fill_in "item[memo]", with: memo

          wait_for_cbox_opened { click_on I18n.t("ss.apis.groups.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on daily_report_group.section_name }
      end
      within "form#item-form" do
        within "#addon-basic" do
          expect(page).to have_css("[data-id='#{daily_report_group.id}']", text: daily_report_group.name)
        end
        click_on I18n.t('gws/daily_report.buttons.save_and_categorize')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      form = Gws::DailyReport::Form.site(site).find_by(name: name)
      expect(form.name).to eq name
      expect(form.year).to eq year
      expect(form.order).to eq order
      expect(form.memo).to eq memo.gsub("\n", "\r\n")
      expect(form.daily_report_group_id).to eq daily_report_group.id

      #
      # edit
      #
      visit gws_daily_report_forms_path(site: site)
      click_on name
      within ".nav-menu" do
        click_on I18n.t('ss.links.edit')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('gws/daily_report.buttons.save_and_categorize')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      form.reload
      expect(form.name).to eq name2
      expect(form.year).to eq year
      expect(form.order).to eq order
      expect(form.memo).to eq memo.gsub("\n", "\r\n")
      expect(form.daily_report_group_id).to eq daily_report_group.id

      #
      # delete
      #
      visit gws_daily_report_forms_path(site: site)
      click_on name2
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::DailyReport::Form.all.count).to eq 0
      expect { Gws::DailyReport::Form.find(form.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
