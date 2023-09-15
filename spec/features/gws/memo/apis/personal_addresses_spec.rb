require 'spec_helper'

describe Gws::Memo::Apis::PersonalAddressesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:address_group1) { create :webmail_address_group, cur_user: gws_user, order: 10 }
  let!(:address_group2) { create :webmail_address_group, cur_user: gws_user, order: 20 }
  let!(:address_group3) { create :webmail_address_group, cur_user: gws_user, order: 30 }
  let!(:address_group4) { create :webmail_address_group, cur_user: gws_user, order: 40 }
  let!(:address_group5) { create :webmail_address_group, cur_user: gws_user, order: 50 }
  let!(:address_group6) { create :webmail_address_group, cur_user: gws_user, order: 60 }
  let!(:address1) do
    create :webmail_address, cur_user: gws_user, address_group: address_group1, member: gws_user, name: "A", kana: "A"
  end
  let!(:address2) do
    create :webmail_address, cur_user: gws_user, address_group: address_group2, member: gws_user, name: "B", kana: "B"
  end
  let!(:address3) do
    create :webmail_address, cur_user: gws_user, address_group: address_group3, member: gws_user, name: "C", kana: "C"
  end
  let!(:address4) do
    create :webmail_address, cur_user: gws_user, address_group: address_group4, member: gws_user, name: "D", kana: "D"
  end
  let!(:address5) do
    create :webmail_address, cur_user: gws_user, address_group: address_group5, member: gws_user, name: "E", kana: "E"
  end
  let!(:address6) do
    create :webmail_address, cur_user: gws_user, address_group: address_group6, member: gws_user, name: "F", kana: "F"
  end

  before do
    @save = described_class::MAX_ITEMS_PER_PAGE
    described_class.send(:remove_const, :MAX_ITEMS_PER_PAGE)
    described_class.const_set(:MAX_ITEMS_PER_PAGE, 5)

    login_gws_user
  end

  after do
    described_class.send(:remove_const, :MAX_ITEMS_PER_PAGE)
    described_class.const_set(:MAX_ITEMS_PER_PAGE, @save)
  end

  describe "tab and pagination" do
    it do
      visit gws_memo_messages_path(site: site, folder: "INBOX")
      click_on I18n.t("ss.links.new")
      wait_for_js_ready

      within "dl.to" do
        wait_cbox_open { click_on I18n.t("mongoid.models.webmail/address") }
      end

      wait_for_cbox do
        expect(page).to have_css(".gws-tabs .current", text: Webmail::Address.model_name.human)
        within "#gws-memo-persona-address-personal" do
          expect(page).to have_css(".list-item", text: address1.name)
          expect(page).to have_css(".pagination .current", text: "1")
        end

        # change tab to group
        js_click first(".gws-tabs a[href='#gws-memo-persona-address-group']")
        wait_for_js_ready

        expect(page).to have_css(".gws-tabs .current", text: Webmail::AddressGroup.model_name.human)
        within "#gws-memo-persona-address-group" do
          expect(page).to have_css(".list-item", text: address_group1.name)
          expect(page).to have_css(".pagination .current", text: "1")
        end

        # move next page on group
        within "#gws-memo-persona-address-group" do
          js_click first(".pagination .next a")
        end
        wait_for_js_ready

        # selected tab is kept
        expect(page).to have_css(".gws-tabs .current", text: Webmail::AddressGroup.model_name.human)
        within "#gws-memo-persona-address-group" do
          expect(page).to have_css(".list-item", text: address_group6.name)
          expect(page).to have_css(".pagination .current", text: "2")
        end

        # back tab to address
        js_click first(".gws-tabs a[href='#gws-memo-persona-address-personal']")
        wait_for_js_ready

        expect(page).to have_css(".gws-tabs .current", text: Webmail::Address.model_name.human)
        # current page is still at 1
        within "#gws-memo-persona-address-personal" do
          expect(page).to have_css(".list-item", text: address1.name)
          expect(page).to have_css(".pagination .current", text: "1")
        end
      end
    end
  end
end
