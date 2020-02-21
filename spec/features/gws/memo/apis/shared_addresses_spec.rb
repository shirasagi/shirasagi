require 'spec_helper'

describe Gws::Memo::Apis::SharedAddressesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:shared_address_group1) { create :gws_shared_address_group, order: 10, readable_setting_range: "public" }
  let!(:shared_address_group2) { create :gws_shared_address_group, order: 20, readable_setting_range: "public" }
  let!(:shared_address_group3) { create :gws_shared_address_group, order: 30, readable_setting_range: "public" }
  let!(:shared_address_group4) { create :gws_shared_address_group, order: 40, readable_setting_range: "public" }
  let!(:shared_address_group5) { create :gws_shared_address_group, order: 50, readable_setting_range: "public" }
  let!(:shared_address_group6) { create :gws_shared_address_group, order: 60, readable_setting_range: "public" }
  let!(:shared_address1) do
    create(
      :gws_shared_address_address, address_group: shared_address_group1, member: gws_user, name: "A", kana: "A",
      readable_setting_range: "public"
    )
  end
  let!(:shared_address2) do
    create(
      :gws_shared_address_address, address_group: shared_address_group2, member: gws_user, name: "B", kana: "B",
      readable_setting_range: "public"
    )
  end
  let!(:shared_address3) do
    create(
      :gws_shared_address_address, address_group: shared_address_group3, member: gws_user, name: "C", kana: "C",
      readable_setting_range: "public"
    )
  end
  let!(:shared_address4) do
    create(
      :gws_shared_address_address, address_group: shared_address_group4, member: gws_user, name: "D", kana: "D",
      readable_setting_range: "public"
    )
  end
  let!(:shared_address5) do
    create(
      :gws_shared_address_address, address_group: shared_address_group5, member: gws_user, name: "E", kana: "E",
      readable_setting_range: "public"
    )
  end
  let!(:shared_address6) do
    create(
      :gws_shared_address_address, address_group: shared_address_group6, member: gws_user, name: "F", kana: "F",
      readable_setting_range: "public"
    )
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

      within "dl.to" do
        click_on I18n.t("modules.gws/shared_address")
      end

      within "#ajax-box" do
        expect(page).to have_css(".gws-tabs .current", text: Gws::SharedAddress::Address.model_name.human)
      end
      within "#gws-memo-persona-address-personal" do
        expect(page).to have_css(".list-item", text: shared_address1.name)
        expect(page).to have_css(".pagination .current", text: "1")
      end

      # change tab to group
      within "#ajax-box" do
        first(".gws-tabs a[href='#gws-memo-persona-address-group']").click
      end

      within "#ajax-box" do
        expect(page).to have_css(".gws-tabs .current", text: Gws::SharedAddress::Group.model_name.human)
      end
      within "#gws-memo-persona-address-group" do
        expect(page).to have_css(".list-item", text: shared_address_group1.name)
        expect(page).to have_css(".pagination .current", text: "1")
      end

      # move next page on group
      within "#gws-memo-persona-address-group" do
        first(".pagination .next a").click
      end

      # selected tab is kept
      within "#ajax-box" do
        expect(page).to have_css(".gws-tabs .current", text: Gws::SharedAddress::Group.model_name.human)
      end
      within "#gws-memo-persona-address-group" do
        expect(page).to have_css(".list-item", text: shared_address_group6.name)
        expect(page).to have_css(".pagination .current", text: "2")
      end

      # back tab to address
      within "#ajax-box" do
        first(".gws-tabs a[href='#gws-memo-persona-address-personal']").click
      end

      within "#ajax-box" do
        expect(page).to have_css(".gws-tabs .current", text: Gws::SharedAddress::Address.model_name.human)
      end
      # current page is still at 1
      within "#gws-memo-persona-address-personal" do
        expect(page).to have_css(".list-item", text: shared_address1.name)
        expect(page).to have_css(".pagination .current", text: "1")
      end
    end
  end
end
