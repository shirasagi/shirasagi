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
      wait_for_notice I18n.t("ss.notice.saved")

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
      wait_for_notice I18n.t("ss.notice.saved")

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
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Notice::Category.all.count).to eq 0
    end
  end

  context "delete parent" do
    let!(:category0) { create :gws_notice_category, cur_site: site }
    let!(:category1) { create :gws_notice_category, cur_site: site, name: "#{category0.name}/#{unique_id}" }

    it do
      login_gws_user to: gws_notice_categories_path(site: site)
      within "[data-id='#{category0.id}']" do
        click_on category0.name
      end
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_error I18n.t("mongoid.errors.models.gws/notice/category.found_children")
    end
  end
end
