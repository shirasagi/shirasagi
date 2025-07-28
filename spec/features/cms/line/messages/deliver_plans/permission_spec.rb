require 'spec_helper'

describe "cms/line/messages/deliver_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }

  let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }

  let!(:permissions) { %w(use_private_cms_line_messages) }
  let!(:role) { create :cms_role, name: unique_id, permissions: permissions }
  let!(:user1) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group1.id], cms_role_ids: [role.id] }
  let!(:user2) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group1.id], cms_role_ids: [role.id] }
  let!(:user3) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group2.id], cms_role_ids: [role.id] }

  let(:index_path) { cms_line_messages_path site }
  let(:new_path) { new_cms_line_message_path site }
  let(:logs_path) { cms_line_deliver_logs_path site }

  let(:name) { unique_id }
  let(:deliver_date) { Time.zone.today.advance(days: -1).strftime("%Y/%m/%d %H:%M") }

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  def add_template
    within "#addon-cms-agents-addons-line-message-body" do
      click_on I18n.t("cms.buttons.add_template")
    end
    within ".line-select-message-type" do
      first(".message-type.text").click
    end
    within "#addon-cms-agents-addons-line-template-text" do
      expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/text"))
      fill_in "item[text]", with: unique_id
    end

    within "footer.send" do
      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t('ss.notice.saved')
  end

  def add_deliver_plans(*dates)
    within "#addon-cms-agents-addons-line-message-deliver_plan" do
      expect(page).to have_text(I18n.t("cms.notices.line_deliver_plans_empty"))
      click_on "設定する"
    end
    dates.each do |date|
      within "#menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[deliver_date]", with: date
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end
    within "#menu" do
      click_on I18n.t("ss.links.back")
    end
  end

  it "#new" do
    # create by user1
    login_user(user1)
    visit new_path

    within "form#item-form" do
      fill_in "item[name]", with: name
      select I18n.t("cms.options.line_deliver_condition_state.broadcast"), from: 'item[deliver_condition_state]'
      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t('ss.notice.saved')

    add_deliver_plans(deliver_date)

    add_template

    within "#menu" do
      expect(page).to have_link I18n.t("ss.links.deliver")
      click_on I18n.t("ss.links.deliver")
    end

    within ".main-box" do
      expect(page).to have_css("header", text: I18n.t("cms.options.deliver_mode.main"))
    end

    capture_line_bot_client do |capture|
      perform_enqueued_jobs do
        within "footer.send" do
          page.accept_confirm do
            click_on I18n.t("ss.links.deliver")
          end
        end
        wait_for_notice I18n.t('ss.notice.started_deliver')
      end

      expect(capture.broadcast.count).to eq 1
      expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
    end

    # edit by user1
    login_user(user2)
    visit index_path
    within ".list-items" do
      expect(page).to have_selector(".list-item a", text: name)
      click_on name
    end

    add_deliver_plans(deliver_date)

    add_template

    within "#menu" do
      expect(page).to have_link I18n.t("ss.links.deliver")
      click_on I18n.t("ss.links.deliver")
    end

    within ".main-box" do
      expect(page).to have_css("header", text: I18n.t("cms.options.deliver_mode.main"))
    end

    capture_line_bot_client do |capture|
      perform_enqueued_jobs do
        within "footer.send" do
          page.accept_confirm do
            click_on I18n.t("ss.links.deliver")
          end
        end
        wait_for_notice I18n.t('ss.notice.started_deliver')
      end

      expect(capture.broadcast.count).to eq 1
      expect(Cms::SnsPostLog::LineDeliver.count).to eq 2
    end

    # login by user2
    login_user(user3)
    visit index_path
    within ".list-items" do
      expect(page).to have_no_selector(".list-item a")
    end

    expect(Cms::Line::Message.site(site).count).to eq 1
    item = Cms::Line::Message.site(site).last
    visit cms_line_message_path site, item
    within "#addon-basic" do
      expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
    end
    visit cms_line_message_deliver_plans_path site, item
    within "#addon-basic" do
      expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
    end
  end
end
