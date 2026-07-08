require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:permissions) do
    Gws::Role.permission_names - %w(delete_other_gws_board_topics edit_other_gws_board_topics trash_other_gws_board_topics)
  end
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }

  let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: [role.id] }
  let!(:user2) { create :gws_user, group_ids: [group.id], gws_role_ids: [role.id] }

  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:category) { create :gws_board_category, subscribed_group_ids: user.group_ids }

  let!(:item1) { create :gws_board_topic, category_ids: [ category.id ], notify_state: "enabled", group_ids: user.group_ids }
  let!(:item2) { create :gws_board_topic, category_ids: [ category.id ], notify_state: "enabled", group_ids: [group.id] }

  context "soft_delete" do
    it do
      login_user(user)
      visit gws_board_topic_path(site: site, mode: '-', category: '-', id: item2)

      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.edit")
        expect(page).to have_link I18n.t("ss.links.delete")
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(SS::Notification.count).to eq 1
      notification = SS::Notification.where(subject: /#{item2.name}/).first
      expect(notification).to be_present
      expect(notification.member_ids.include?(user.id)).to be_falsey
      expect(notification.member_ids.include?(user1.id)).to be_truthy
      expect(notification.member_ids.include?(user2.id)).to be_falsey
    end
  end

  context "soft_delete with no permission case" do
    it do
      login_user(user1)
      visit gws_board_topic_path(site: site, mode: '-', category: '-', id: item2)

      within "#menu" do
        expect(page).to have_no_link I18n.t("ss.links.edit")
        expect(page).to have_no_link I18n.t("ss.links.delete")
      end
    end
  end

  context "soft_delete_all" do
    it do
      login_user(user)
      visit gws_board_topics_path(site: site, mode: '-', category: '-')

      # check menu link
      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        click_link item1.name
      end
      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.edit")
        expect(page).to have_link I18n.t("ss.links.delete")
        click_on I18n.t("ss.links.back_to_index")
      end
      within ".list-items" do
        click_link item2.name
      end
      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.edit")
        expect(page).to have_link I18n.t("ss.links.delete")
        click_on I18n.t("ss.links.back_to_index")
      end

      # check soft_destroy_all
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert(I18n.t("ss.confirm.delete")) do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      within ".list-items" do
        expect(page).to have_no_selector(".list-item")
      end
      expect(SS::Notification.count).to eq 2
      notification = SS::Notification.where(subject: /#{item1.name}/).first
      expect(notification).to be_present
      expect(notification.member_ids.include?(user.id)).to be_falsey
      expect(notification.member_ids.include?(user1.id)).to be_truthy
      expect(notification.member_ids.include?(user2.id)).to be_falsey

      notification = SS::Notification.where(subject: /#{item2.name}/).first
      expect(notification).to be_present
      expect(notification.member_ids.include?(user.id)).to be_falsey
      expect(notification.member_ids.include?(user1.id)).to be_truthy
      expect(notification.member_ids.include?(user2.id)).to be_falsey
    end
  end

  context "soft_delete_all with no permission case" do
    it do
      login_user(user1)
      visit gws_board_topics_path(site: site, mode: '-', category: '-')

      # check menu link
      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        click_link item1.name
      end
      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.edit")
        expect(page).to have_link I18n.t("ss.links.delete")
        click_on I18n.t("ss.links.back_to_index")
      end
      within ".list-items" do
        click_link item2.name
      end
      within "#menu" do
        expect(page).to have_no_link I18n.t("ss.links.edit")
        expect(page).to have_no_link I18n.t("ss.links.delete")
        click_on I18n.t("ss.links.back_to_index")
      end

      # check soft_destroy_all
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert(I18n.t("ss.confirm.delete")) do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_link item2.name
      end
      expect(SS::Notification.count).to eq 1
      notification = SS::Notification.where(subject: /#{item1.name}/).first
      expect(notification).to be_present
      expect(notification.member_ids.include?(user.id)).to be_truthy
      expect(notification.member_ids.include?(user1.id)).to be_falsey
      expect(notification.member_ids.include?(user2.id)).to be_falsey

      notification = SS::Notification.where(subject: /#{item2.name}/).first
      expect(notification).to be_blank
    end
  end
end
