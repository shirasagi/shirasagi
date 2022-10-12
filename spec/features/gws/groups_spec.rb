require 'spec_helper'

describe "gws_groups", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { "#{site.name}/#{unique_id}" }
    let(:name2) { "#{site.name}/#{unique_id}" }

    it do
      #
      # Create
      #
      visit gws_groups_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item = Gws::Group.all.find_by(name: name)
      expect(item.name).to eq name
      expect(item.order).to be_blank
      expect(item.activation_date).to be_blank
      expect(item.expiration_date).to be_blank
      expect(item.domains).to be_blank
      expect(item.gws_use).to be_blank

      #
      # Update
      #
      visit gws_groups_path(site: site)
      click_on item.trailing_name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item = Gws::Group.unscoped.find(item.id)
      expect(item.name).to eq name2

      #
      # Delete (Soft Delete)
      #
      visit gws_groups_path(site: site)
      click_on item.trailing_name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      item = Gws::Group.unscoped.find(item.id)
      expect(item.expiration_date).to be_present

      # #
      # # Delete (Hard Delete)
      # #
      # visit gws_groups_path(site: site)
      # within "form.index-search" do
      #   select I18n.t("ss.options.state.disabled"), from: "s[state]"
      #   click_on I18n.t("ss.buttons.search")
      # end
      # click_on item.trailing_name
      # within ".nav-menu" do
      #   click_on I18n.t("ss.links.delete")
      # end
      # within "form" do
      #   click_on I18n.t('ss.buttons.delete')
      # end
      # wait_for_notice I18n.t("ss.notice.deleted")
      #
      # expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "download all" do
    let!(:item1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:item2) { create :gws_group, name: "#{site.name}/#{unique_id}", expiration_date: 1.hour.ago }

    it do
      visit gws_groups_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to be > 2
          expect(csv_table[0][Gws::Group.t(:id)]).to be_present
          expect(csv_table[0][Gws::Group.t(:name)]).to be_present
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/groups"
        expect(history.path).to eq download_all_gws_groups_path(site: site)
        expect(history.action).to eq "download_all"
      end
    end
  end
end
