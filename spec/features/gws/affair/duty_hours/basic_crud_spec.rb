require 'spec_helper'

describe "gws_affair_duty_hours", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:name) { unique_id }
  let(:name2) { unique_id }

  before do
    login_gws_user
  end

  context 'basic crud' do
    it do
      #
      # Create
      #
      visit gws_affair_duty_hours_path(site: site)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Affair::DutyHour.all.count).to eq 1
      item = Gws::Affair::DutyHour.all.first
      expect(item.name).to eq name

      #
      # Update
      #
      visit gws_affair_duty_hours_path(site: site)
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      item.reload
      expect(item.name).to eq name2

      #
      # Delete
      #
      visit gws_affair_duty_hours_path(site: site)
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
