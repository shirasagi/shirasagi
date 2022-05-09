require 'spec_helper'

describe "gws_users", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:default_group) { user.groups.first }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  before do
    Gws::User.find(user.id).tap do |user|
      # メンバー変数が汚染されるとテストで思わぬ結果をうむ場合がある。
      # そこで、データベースからユーザーをロードし、必要処理を実行後、インスタンスを破棄する。
      user.cur_site = site
      user.in_gws_main_group_id = default_group.id
      user.group_ids = user.group_ids + [ group1.id, group2.id ]
      user.save!
    end
    user.reload
    Gws::User.find(user.id).tap do |user|
      user.cur_site = site
      expect(user.gws_main_group_ids).to include(site.id.to_s => default_group.id)
      expect(user.gws_default_group_ids).to be_blank
    end

    login_gws_user
  end

  context "with main group" do
    it do
      #
      # Change main group
      #
      visit gws_users_path(site: site)
      click_on user.name
      click_on I18n.t("ss.links.edit")

      within "#item-form" do
        within ".mod-gws-user-main-group" do
          wait_cbox_open do
            click_on I18n.t("ss.apis.groups.index")
          end
        end
      end
      wait_for_cbox do
        wait_cbox_close do
          click_on group1.trailing_name
        end
      end
      within "#item-form" do
        within ".mod-gws-user-main-group" do
          expect(page).to have_css(".index", text: group1.trailing_name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::User.find(user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to include(site.id.to_s => group1.id)
        expect(user.gws_default_group_ids).to be_blank
      end

      #
      # Delete main group
      #
      visit gws_users_path(site: site)
      click_on user.name
      click_on I18n.t("ss.links.edit")

      within "#item-form" do
        within ".mod-gws-user-main-group" do
          click_on I18n.t("ss.buttons.delete")
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::User.find(user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to be_blank
        expect(user.gws_default_group_ids).to be_blank
      end

      #
      # Try to change group where user doesn't belong
      #
      visit gws_users_path(site: site)
      click_on user.name
      click_on I18n.t("ss.links.edit")

      within "#item-form" do
        within ".mod-gws-user-main-group" do
          wait_cbox_open do
            click_on I18n.t("ss.apis.groups.index")
          end
        end
      end
      wait_for_cbox do
        wait_cbox_close do
          click_on group3.trailing_name
        end
      end
      within "#item-form" do
        within ".mod-gws-user-main-group" do
          expect(page).to have_css(".index", text: group3.trailing_name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      message = I18n.t("errors.format", attribute: Gws::User.t(:gws_main_group_ids), message: I18n.t("errors.messages.invalid"))
      expect(page).to have_css("#errorExplanation li", text: message)
    end
  end

  context "with default group" do
    it do
      #
      # Change default group
      #
      visit gws_users_path(site: site)
      click_on user.name
      click_on I18n.t("ss.links.edit")

      within "#item-form" do
        within ".mod-gws-user-default-group" do
          wait_cbox_open do
            click_on I18n.t("ss.apis.groups.index")
          end
        end
      end
      wait_for_cbox do
        wait_cbox_close do
          click_on group2.trailing_name
        end
      end
      within "#item-form" do
        within ".mod-gws-user-default-group" do
          expect(page).to have_css(".index", text: group2.trailing_name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::User.find(user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to include(site.id.to_s => default_group.id)
        expect(user.gws_default_group_ids).to include(site.id.to_s => group2.id)
      end

      #
      # Delete main group
      #
      visit gws_users_path(site: site)
      click_on user.name
      click_on I18n.t("ss.links.edit")

      within "#item-form" do
        within ".mod-gws-user-default-group" do
          click_on I18n.t("ss.buttons.delete")
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::User.find(user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to include(site.id.to_s => default_group.id)
        expect(user.gws_default_group_ids).to be_blank
      end

      #
      # Try to change group where user doesn't belong
      #
      visit gws_users_path(site: site)
      click_on user.name
      click_on I18n.t("ss.links.edit")

      within "#item-form" do
        within ".mod-gws-user-default-group" do
          wait_cbox_open do
            click_on I18n.t("ss.apis.groups.index")
          end
        end
      end
      wait_for_cbox do
        wait_cbox_close do
          click_on group3.trailing_name
        end
      end
      within "#item-form" do
        within ".mod-gws-user-default-group" do
          expect(page).to have_css(".index", text: group3.trailing_name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      message = I18n.t(
        "errors.format", attribute: Gws::User.t(:gws_default_group_ids), message: I18n.t("errors.messages.invalid"))
      expect(page).to have_css("#errorExplanation li", text: message)
    end
  end
end
