require 'spec_helper'

describe "gws_custom_groups", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }

    it do
      #
      # Create
      #
      visit gws_custom_groups_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        within '#addon-gws-agents-addons-member' do
          wait_cbox_open do
            click_on I18n.t("ss.apis.users.index")
          end
        end
      end
      wait_for_cbox do
        wait_cbox_close do
          click_on gws_user.long_name
        end
      end
      page.accept_confirm I18n.t("gws.confirm.readable_setting.empty") do
        within "form#item-form" do
          fill_in "item[name]", with: name
          click_on I18n.t('ss.buttons.save')
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      #
      # Update
      #
      expect(Gws::CustomGroup.all.count).to eq 1
      item = Gws::CustomGroup.all.first
      expect(item.name).to eq name
      expect(item.order).to be_blank
      expect(item.member_ids).to eq [ gws_user.id ]

      visit gws_custom_groups_path(site: site)
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      page.accept_confirm I18n.t("gws.confirm.readable_setting.empty") do
        within "form#item-form" do
          fill_in "item[name]", with: name2
          click_on I18n.t('ss.buttons.save')
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.name).to eq name2

      #
      # Delete
      #
      visit gws_custom_groups_path(site: site)
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "download all" do
    let!(:item1) { create :gws_custom_group, cur_site: site }

    it do
      visit gws_custom_groups_path(site: site)
      click_on I18n.t("ss.links.download")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 1
        expect(csv_table[0][Gws::CustomGroup.t(:id)]).to be_present
        expect(csv_table[0][Gws::CustomGroup.t(:name)]).to be_present
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/custom_groups"
        expect(history.path).to eq download_all_gws_custom_groups_path(site: site)
        expect(history.action).to eq "download_all"
      end
    end
  end
end
