require 'spec_helper'

describe "cms/line/messages test_deliver", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let(:index_path) { cms_line_messages_path site }
  let(:new_path) { new_cms_line_message_path site }
  let(:logs_path) { cms_line_deliver_logs_path site }

  let(:name) { unique_id }
  let(:today) { Time.zone.today }
  let(:child1_birth) { { era: "seireki", year: (today.year - 1), month: today.month, day: today.day } }

  let!(:deliver_category1) { create :cms_line_deliver_category_category }
  let!(:deliver_category1_1) { create :cms_line_deliver_category_category, parent: deliver_category1 }
  let!(:deliver_category1_2) { create :cms_line_deliver_category_category, parent: deliver_category1 }
  let!(:deliver_category1_3) { create :cms_line_deliver_category_category, parent: deliver_category1 }

  let!(:deliver_category2) { create :cms_line_deliver_category_category }
  let!(:deliver_category2_1) { create :cms_line_deliver_category_category, parent: deliver_category2 }
  let!(:deliver_category2_2) { create :cms_line_deliver_category_category, parent: deliver_category2 }
  let!(:deliver_category2_3) { create :cms_line_deliver_category_category, parent: deliver_category2 }

  # active members
  let!(:member1) { create(:cms_line_member, name: "member1") }
  let!(:member2) { create(:cms_line_member, name: "member2", child1_name: unique_id, in_child1_birth: child1_birth) }
  let!(:member3) { create(:cms_line_member, name: "member3", deliver_category_ids: [deliver_category1_1.id]) }

  # expired members
  let!(:member4) { create(:cms_member, name: "member4", subscribe_line_message: "active") }
  let!(:member5) { create(:cms_line_member, name: "member5", subscribe_line_message: "expired") }
  let!(:member6) { create(:cms_line_member, name: "member6", subscribe_line_message: "active", state: "disabled") }

  # test members
  let!(:test_member1) { create(:cms_line_test_member, name: "test1") }
  let!(:test_member2) { create(:cms_line_test_member, name: "test2") }
  let!(:test_member3) { create(:cms_line_test_member, name: "test3") }

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

  def check_deliver_members(selector)
    within selector do
      first(".ajax-box", text: "確認する").click
    end
    wait_for_cbox do
      expect(page).to have_text(targets_count)
      targets.each do |member|
        expect(page).to have_css(".list-item", text: member.name)
        expect(page).to have_css(".list-item", text: member.oauth_id)
      end
      non_targets.each do |member|
        expect(page).to have_no_css(".list-item", text: member.name)
      end
    end
    visit current_path
  end

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  context "multicast_with_no_condition" do
    let(:targets) { [test_member1, test_member2, test_member3] }
    let(:non_targets) { [member1, member2, member3, member4, member5, member6] }
    let(:targets_count) { "#{I18n.t("cms.member")}#{targets.size}#{I18n.t("ss.units.count")}" }

    before { login_cms_user }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        select I18n.t("cms.options.line_deliver_condition_state.multicast_with_no_condition"), from: 'item[deliver_condition_state]'
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "#addon-basic" do
        expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.draft"))
      end
      within "#menu" do
        expect(page).to have_no_link I18n.t("ss.links.test_deliver")
      end

      add_template

      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.test_deliver")
        click_on I18n.t("ss.links.test_deliver")
      end

      within ".main-box" do
        expect(page).to have_css("header", text: I18n.t("cms.options.deliver_mode.test"))
      end

      capture_line_bot_client do |capture|
        perform_enqueued_jobs do
          within "footer.send" do
            page.accept_confirm do
              click_on I18n.t("ss.links.deliver")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_test_deliver'))
        end

        expect(capture.multicast.count).to eq 1
        expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
        expect(Cms::SnsPostLog::LineDeliver.count).to eq 1

        visit current_path
        within "#addon-basic" do
          expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.draft"))
        end

        visit index_path
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: name)
          expect(page).to have_css(".list-item .meta .state-draft", text: I18n.t("cms.options.deliver_state.draft"))
        end

        visit logs_path
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: "[#{I18n.t("cms.options.deliver_mode.test")}] #{name}")
          expect(page).to have_css(".list-item .meta .action", text: "multicast")
          expect(page).to have_css(".list-item .meta .state", text: I18n.t("cms.options.sns_post_log_state.success"))
          click_on "[#{I18n.t("cms.options.deliver_mode.test")}] #{name}"
        end
        check_deliver_members("#addon-basic")
      end
    end
  end
end
