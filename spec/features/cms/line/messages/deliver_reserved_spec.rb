require 'spec_helper'

describe "cms/line/messages deliver_reserved multicast_with_no_condition", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let(:index_path) { cms_line_messages_path site }
  let(:new_path) { new_cms_line_message_path site }
  let(:logs_path) { cms_line_deliver_logs_path site }

  let(:name) { unique_id }
  let(:today) { Time.zone.today }

  let(:brithday1) { today.advance(years: -1) }
  let(:brithday2) { today.advance(years: -1, days: 3) }

  let(:child1_birth) { { era: "seireki", year: brithday1.year, month: brithday1.month, day: brithday1.day } }
  let(:child2_birth) { { era: "seireki", year: brithday2.year, month: brithday2.month, day: brithday2.day } }

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
  let!(:member3) { create(:cms_line_member, name: "member3", child1_name: unique_id, in_child1_birth: child2_birth) }

  # expired members
  let!(:member4) { create(:cms_member, name: "member4", subscribe_line_message: "active") }
  let!(:member5) { create(:cms_line_member, name: "member5", subscribe_line_message: "expired") }
  let!(:member6) { create(:cms_line_member, name: "member6", subscribe_line_message: "active", state: "disabled") }

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
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
    within "#menu" do
      click_on I18n.t("ss.links.back")
    end
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

  def execute_reserved_job
    Cms::Line::DeliverReservedJob.bind(site_id: site).perform_now
  end

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  context "deliver now" do
    context "multicast_with_no_condition" do
      let(:deliver_date) { Time.zone.today.advance(days: -1).strftime("%Y/%m/%d %H:%M") }
      let(:targets) { [member1, member2, member3] }
      let(:non_targets) { [member4, member5, member6] }
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
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          end

          expect(capture.multicast.count).to eq 1
          expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
          expect(Cms::SnsPostLog::LineDeliver.count).to eq 1

          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit index_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: name)
            expect(page).to have_css(".list-item .meta .state-completed", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit logs_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}")
            expect(page).to have_css(".list-item .meta .action", text: "multicast")
            expect(page).to have_css(".list-item .meta .state", text: I18n.t("cms.options.sns_post_log_state.success"))
            click_on "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}"
          end
          check_deliver_members("#addon-basic")
        end
      end
    end
  end

  context "deliver 1 days ago" do
    context "multicast_with_no_condition" do
      let(:deliver_date) { Time.zone.today.advance(days: 1).strftime("%Y/%m/%d %H:%M") }
      let(:targets) { [member1, member2, member3] }
      let(:non_targets) { [member4, member5, member6] }
      let(:targets_count) { "#{I18n.t("cms.member")}#{targets.size}#{I18n.t("ss.units.count")}" }

      before { login_cms_user }

      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          select I18n.t("cms.options.line_deliver_condition_state.multicast_with_no_condition"), from: 'item[deliver_condition_state]'
        end
        click_on I18n.t("ss.buttons.save")
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

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
          within "footer.send" do
            page.accept_confirm do
              click_on I18n.t("ss.links.deliver")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          expect(enqueued_jobs.size).to eq 0

          Timecop.travel(today.advance(days: 1)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
          end

          visit current_path

          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit index_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: name)
            expect(page).to have_css(".list-item .meta .state-completed", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit logs_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}")
            expect(page).to have_css(".list-item .meta .action", text: "multicast")
            expect(page).to have_css(".list-item .meta .state", text: I18n.t("cms.options.sns_post_log_state.success"))
            click_on "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}"
          end
          check_deliver_members("#addon-basic")
        end
      end
    end

    context "multicast_with_input_condition (year)" do
      let(:deliver_date) { Time.zone.today.advance(days: 1).strftime("%Y/%m/%d %H:%M") }

      let(:targets) { [member2] }
      let(:non_targets) { [member1, member3, member4, member5, member6] }
      let(:targets_count) { "#{I18n.t("cms.member")}#{targets.size}#{I18n.t("ss.units.count")}" }

      before { login_cms_user }

      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          select I18n.t("cms.options.line_deliver_condition_state.multicast_with_input_condition"), from: 'item[deliver_condition_state]'
          fill_in "item[lower_year1]", with: 1
          fill_in "item[upper_year1]", with: 1
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

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
          within "footer.send" do
            page.accept_confirm do
              click_on I18n.t("ss.links.deliver")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          expect(enqueued_jobs.size).to eq 0

          Timecop.travel(today.advance(days: 1)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
          end

          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit index_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: name)
            expect(page).to have_css(".list-item .meta .state-completed", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit logs_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}")
            expect(page).to have_css(".list-item .meta .action", text: "multicast")
            expect(page).to have_css(".list-item .meta .state", text: I18n.t("cms.options.sns_post_log_state.success"))
            click_on "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}"
          end
          check_deliver_members("#addon-basic")
        end
      end
    end
  end

  context "deliver 3 days ago" do
    context "multicast_with_no_condition" do
      let(:deliver_date) { Time.zone.today.advance(days: 3).strftime("%Y/%m/%d %H:%M") }
      let(:targets) { [member1, member2, member3] }
      let(:non_targets) { [member4, member5, member6] }
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
          within "footer.send" do
            page.accept_confirm do
              click_on I18n.t("ss.links.deliver")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          expect(enqueued_jobs.size).to eq 0

          Timecop.travel(today.advance(days: 1)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 0
          end

          Timecop.travel(today.advance(days: 3)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
          end

          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit index_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: name)
            expect(page).to have_css(".list-item .meta .state-completed", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit logs_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}")
            expect(page).to have_css(".list-item .meta .action", text: "multicast")
            expect(page).to have_css(".list-item .meta .state", text: I18n.t("cms.options.sns_post_log_state.success"))
            click_on "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}"
          end
          check_deliver_members("#addon-basic")
        end
      end
    end

    context "multicast_with_input_condition (year)" do
      let(:deliver_date) { Time.zone.today.advance(days: 3).strftime("%Y/%m/%d %H:%M") }

      let(:targets) { [member2, member3] }
      let(:non_targets) { [member1, member4, member5, member6] }
      let(:targets_count) { "#{I18n.t("cms.member")}#{targets.size}#{I18n.t("ss.units.count")}" }

      before { login_cms_user }

      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          select I18n.t("cms.options.line_deliver_condition_state.multicast_with_input_condition"), from: 'item[deliver_condition_state]'
          fill_in "item[lower_year1]", with: 1
          fill_in "item[upper_year1]", with: 1
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

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
          within "footer.send" do
            page.accept_confirm do
              click_on I18n.t("ss.links.deliver")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          expect(enqueued_jobs.size).to eq 0

          Timecop.travel(today.advance(days: 1)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 0
          end

          Timecop.travel(today.advance(days: 3)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
          end

          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit index_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: name)
            expect(page).to have_css(".list-item .meta .state-completed", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit logs_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}")
            expect(page).to have_css(".list-item .meta .action", text: "multicast")
            expect(page).to have_css(".list-item .meta .state", text: I18n.t("cms.options.sns_post_log_state.success"))
            click_on "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}"
          end
          check_deliver_members("#addon-basic")
        end
      end
    end
  end

  context "deliver 1,3,5 days ago" do
    context "multicast_with_no_condition" do
      let(:deliver_dates) do
        today = Time.zone.today
        [-1, 1, 3, 5].map { |days| today.advance(days: days).strftime("%Y/%m/%d %H:%M") }
      end
      let(:targets) { [member1, member2, member3] }
      let(:non_targets) { [member4, member5, member6] }
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

        add_deliver_plans(*deliver_dates)

        add_template

        within "#menu" do
          expect(page).to have_link I18n.t("ss.links.deliver")
          click_on I18n.t("ss.links.deliver")
        end

        within ".main-box" do
          expect(page).to have_css("header", text: I18n.t("cms.options.deliver_mode.main"))
        end

        capture_line_bot_client do |capture|
          within "footer.send" do
            page.accept_confirm do
              click_on I18n.t("ss.links.deliver")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
          expect(enqueued_jobs.size).to eq 0

          Timecop.travel(today.advance(days: 1)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
          end
          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.ready"))
          end

          Timecop.travel(today.advance(days: 2)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 1
            expect(capture.multicast.count).to eq 1
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
          end
          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.ready"))
          end

          Timecop.travel(today.advance(days: 3)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 2
            expect(capture.multicast.count).to eq 2
            expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 2
          end
          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.ready"))
          end

          Timecop.travel(today.advance(days: 4)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 2
            expect(capture.multicast.count).to eq 2
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 2
          end
          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.ready"))
          end

          Timecop.travel(today.advance(days: 5)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 3
            expect(capture.multicast.count).to eq 3
            expect(capture.multicast.user_ids).to match_array targets.map(&:oauth_id)
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 3
          end
          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
          end

          Timecop.travel(today.advance(days: 6)) do
            execute_reserved_job
            expect(capture.multicast.count).to eq 3
            expect(capture.multicast.count).to eq 3
            expect(Cms::SnsPostLog::LineDeliver.count).to eq 3
          end
          visit current_path
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit index_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: name)
            expect(page).to have_css(".list-item .meta .state-completed", text: I18n.t("cms.options.deliver_state.completed"))
          end

          visit logs_path
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: "[#{I18n.t("cms.options.deliver_mode.main")}] #{name}")
            expect(page).to have_css(".list-item .meta .action", text: "multicast")
            expect(page).to have_css(".list-item .meta .state", text: I18n.t("cms.options.sns_post_log_state.success"))
          end
        end
      end
    end
  end
end
