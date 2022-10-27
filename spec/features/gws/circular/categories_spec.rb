require 'spec_helper'

describe "gws_circular_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:color) { "#481357" }
    let(:order) { rand(10) }

    before { login_gws_user }

    it do
      visit gws_circular_categories_path(site: site)

      #
      # create
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.new')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[color]", with: color + "\n"
        fill_in "item[order]", with: order
        click_on I18n.t('ss.buttons.save')
      end

      category = Gws::Circular::Category.site(site).find_by(name: name)
      expect(category.name).to eq name
      expect(category.color).to eq color
      expect(category.order).to eq order

      expect(page).to have_css("div.addon-body dd", text: name)

      #
      # edit
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.edit')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('ss.buttons.save')
      end

      category.reload
      expect(category.name).to eq name2
      expect(category.color).to eq color
      expect(category.order).to eq order

      expect(page).to have_css("div.addon-body dd", text: name2)

      #
      # index
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.back_to_index')
      end
      within "div.info" do
        expect(page).to have_css("a.title", text: name2)
        click_on name2
      end

      #
      # delete
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end

      category = Gws::Circular::Category.site(site).where(name: name).first
      expect(category).to be_nil

      expect(page).to have_no_css("div.info")
    end
  end

  context "with subscriber" do
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user1) { create :gws_user, group_ids: gws_user.group_ids }
    let(:name) { unique_id }

    before { login_gws_user }

    it do
      visit gws_circular_categories_path(site: site)

      # create
      click_on I18n.t('ss.links.new')

      within "form#item-form" do
        fill_in "item[name]", with: name
        within "#addon-gws-agents-addons-subscription_setting" do
          first(".addon-head h2").click
          click_on I18n.t("ss.apis.groups.index")
        end
      end
      wait_for_cbox do
        click_on group1.trailing_name
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-subscription_setting" do
          click_on I18n.t("ss.apis.users.index")
        end
      end
      wait_for_cbox do
        click_on user1.name
      end
      within "form#item-form" do
        within ".gws-addon-subscription-setting-group" do
          expect(page).to have_css(".ajax-selected", text: group1.trailing_name)
        end
        within ".gws-addon-subscription-setting-member" do
          expect(page).to have_css(".ajax-selected", text: user1.name)
        end
        click_on I18n.t('ss.buttons.save')
      end

      category = Gws::Circular::Category.site(site).find_by(name: name)
      expect(category.name).to eq name
      expect(category.subscribed_group_ids).to include(group1.id)
      expect(category.subscribed_member_ids).to include(user1.id)
    end
  end
end
