require 'spec_helper'

describe "gws_report_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:order) { rand(10) }
    let(:memo) { Array.new(rand(3..10)) { unique_id }.join("\n") }

    before { login_gws_user }

    it do
      #
      # create
      #
      visit gws_report_forms_path(site: site)
      within ".nav-menu" do
        click_on I18n.t('ss.links.new')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[order]", with: order
        fill_in "item[memo]", with: memo

        wait_cbox_open { click_on I18n.t("gws.apis.categories.index") }
      end
      wait_for_cbox do
        click_on category.name
      end
      within "form#item-form" do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      form = Gws::Report::Form.site(site).find_by(name: name)
      expect(form.name).to eq name
      expect(form.order).to eq order
      expect(form.memo).to eq memo.gsub("\n", "\r\n")
      expect(form.category_ids).to eq [ category.id ]

      #
      # edit
      #
      visit gws_report_forms_path(site: site)
      click_on name
      within ".nav-menu" do
        click_on I18n.t('ss.links.edit')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      form.reload
      expect(form.name).to eq name2
      expect(form.order).to eq order
      expect(form.memo).to eq memo.gsub("\n", "\r\n")
      expect(form.category_ids).to eq [ category.id ]

      #
      # delete
      #
      visit gws_report_forms_path(site: site)
      click_on name2
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { Gws::Report::Form.find(form.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
