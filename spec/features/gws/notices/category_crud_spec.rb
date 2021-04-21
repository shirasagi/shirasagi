require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:name) { unique_id }
  let(:color) { "#431423" }
  let(:order) { rand(1..10) }
  let(:name2) { unique_id }

  context "basic crud" do
    before { login_gws_user }

    it do
      #
      # Create
      #
      visit gws_notice_categories_path(site: site)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[color]", with: color
        fill_in "item[order]", with: order

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Gws::Notice::Category.all.count).to eq 1
      Gws::Notice::Category.all.first.tap do |cate|
        expect(cate.name).to eq name
        expect(cate.color).to eq color
        expect(cate.order).to eq order
      end

      #
      # Update
      #
      visit gws_notice_categories_path(site: site)
      click_on name
      click_on I18n.t("ss.buttons.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Gws::Notice::Category.all.count).to eq 1
      Gws::Notice::Category.all.first.tap do |cate|
        expect(cate.name).to eq name2
        expect(cate.color).to eq color
        expect(cate.order).to eq order
      end

      #
      # Delete
      #
      visit gws_notice_categories_path(site: site)
      click_on name2
      click_on I18n.t("ss.buttons.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      expect(Gws::Notice::Category.all.count).to eq 0
    end
  end
end
