require 'spec_helper'

describe "cms/line/messages/deliver_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }

  let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:permissions) { %w(use_private_cms_line_messages) }
  let!(:role) { create :cms_role, name: unique_id, permissions: permissions }
  let!(:user1) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group1.id], cms_role_ids: [role.id] }

  let(:item) { create :cms_line_message, group_ids: [group1.id] }
  let(:index_path) { cms_line_message_deliver_plans_path site, item }

  before { login_user(user1) }

  let(:start_date) { Time.zone.now.beginning_of_month.change(hour: 10, min: 0) }
  let(:end_date) { start_date.advance(days: 6) }

  it do
    visit index_path
    click_on I18n.t("ss.links.new")

    within "form#item-form" do
      fill_in_datetime "item[deliver_date]", with: start_date
      within "#addon-cms-agents-addons-line-deliver_plan-repeat" do
        select I18n.t("gws/schedule.options.repeat_type.daily"), from: "item[repeat_type]"
        select 1, from: "item[interval]"
        fill_in_date "item[repeat_start]", with: start_date
        fill_in_date "item[repeat_end]", with: end_date
      end
      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "table.index" do
      expect(page).to have_selector("tr.list-item", count: 7)
    end
    wait_event_to_fire("ss:checked-all-list-items") { find("table.index .list-head input[type=checkbox]").click }
    within ".list-head-action-destroy" do
      click_on I18n.t("ss.buttons.delete")
    end
    within "footer.send" do
      click_on I18n.t("ss.buttons.delete")
    end
    wait_for_notice I18n.t("ss.notice.deleted")

    within "table.index" do
      expect(page).to have_no_selector("tr.list-item")
    end
  end
end
