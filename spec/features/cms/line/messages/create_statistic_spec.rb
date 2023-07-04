require 'spec_helper'

describe "cms/line/messages create statistic", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let(:index_path) { cms_line_messages_path site }
  let(:new_path) { new_cms_line_message_path site }
  let(:statistics_path) { cms_line_statistics_path site }
  let(:statistic) { Cms::Line::Statistic.last }

  let(:name) { unique_id }

  # active members
  let!(:member1) { create(:cms_line_member, name: "member1") }
  let!(:member2) { create(:cms_line_member, name: "member2") }

  # test members
  let!(:test_member1) { create(:cms_line_test_member, name: "test1") }
  let!(:test_member2) { create(:cms_line_test_member, name: "test2") }

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
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
  end

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!

    login_cms_user
  end

  context "statistic state enabled" do
    context "broadcast" do
      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          select I18n.t("cms.options.line_deliver_condition_state.broadcast"), from: 'item[deliver_condition_state]'
          select I18n.t("ss.options.state.enabled"), from: 'item[statistic_state]'
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

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
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          end

          expect(capture.broadcast.count).to eq 1
          expect(capture.get_aggregation_info.count).to eq 0

          expect(Cms::Line::Statistic.count).to eq 1
          visit statistics_path

          expect(page).to have_link name
          click_on name

          ensure_addon_opened("#addon-cms-agents-addons-line-statistic-info")
          within "#addon-cms-agents-addons-line-statistic-info" do
            expect(page).to have_css("dd", text: statistic.request_id)
          end
        end
      end
    end

    context "multicast_with_no_condition" do
      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          select I18n.t("cms.options.line_deliver_condition_state.multicast_with_no_condition"), from: 'item[deliver_condition_state]'
          select I18n.t("ss.options.state.enabled"), from: 'item[statistic_state]'
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

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
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          end

          expect(capture.multicast.count).to eq 1
          expect(capture.get_aggregation_info.count).to eq 1

          expect(Cms::Line::Statistic.count).to eq 1
          visit statistics_path

          expect(page).to have_link name
          click_on name

          ensure_addon_opened("#addon-cms-agents-addons-line-statistic-info")
          within "#addon-cms-agents-addons-line-statistic-info" do
            expect(page).to have_css("dd", text: statistic.aggregation_unit)
          end
        end
      end
    end
  end

  context "statistic state disabled" do
    context "broadcast" do
      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          select I18n.t("cms.options.line_deliver_condition_state.broadcast"), from: 'item[deliver_condition_state]'
          select I18n.t("ss.options.state.disabled"), from: 'item[statistic_state]'
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

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
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          end

          expect(capture.broadcast.count).to eq 1
          expect(capture.get_aggregation_info.count).to eq 0
          expect(Cms::Line::Statistic.count).to eq 0
        end
      end
    end

    context "multicast_with_no_condition" do
      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          select I18n.t("cms.options.line_deliver_condition_state.multicast_with_no_condition"), from: 'item[deliver_condition_state]'
          select I18n.t("ss.options.state.disabled"), from: 'item[statistic_state]'
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

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
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          end

          expect(capture.multicast.count).to eq 1
          expect(capture.get_aggregation_info.count).to eq 0
          expect(Cms::Line::Statistic.count).to eq 0
        end
      end
    end
  end
end
