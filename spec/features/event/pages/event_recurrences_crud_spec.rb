require 'spec_helper'

describe "event_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :event_node_page, cur_site: site }

  before { login_cms_user }

  context "event recurrences" do
    let(:name) { "name-#{unique_id}" }
    let(:event_name) { "event_name-#{unique_id}" }
    let(:start_on1) { Date.parse("2023/02/06") }
    let(:until_on1) { (start_on1 + 2.days).to_date }
    let(:event_deadline) { (start_on1 + 2.months).to_date }

    context "only start_on" do
      it do
        visit event_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name

          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            fill_in "item[event_name]", with: event_name
            fill_in_date "item[event_deadline]", with: event_deadline
            within ".event-recurrence[data-index='1']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        expect(Event::Page.all.count).to eq 1
        item = Event::Page.all.first
        expect(item.site_id).to eq site.id
        expect(item.filename).to start_with "#{node.filename}/"
        expect(item.name).to eq name
        expect(item.event_name).to eq event_name
        expect(item.event_deadline.in_time_zone).to eq event_deadline.in_time_zone
        expect(item.event_recurrences).to have(1).items
        item.event_recurrences[0].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on1.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on1.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq start_on1.in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        expect(item.event_dates).to eq [ start_on1 ]
      end
    end

    context "start_on and until_on" do
      it do
        visit event_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name

          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            fill_in "item[event_name]", with: event_name
            fill_in_date "item[event_deadline]", with: event_deadline
            within ".event-recurrence[data-index='1']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1
              fill_in_date "item[event_recurrences][][in_until_on]", with: until_on1
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        expect(Event::Page.all.count).to eq 1
        item = Event::Page.all.first
        expect(item.site_id).to eq site.id
        expect(item.filename).to start_with "#{node.filename}/"
        expect(item.name).to eq name
        expect(item.event_name).to eq event_name
        expect(item.event_deadline.in_time_zone).to eq event_deadline.in_time_zone
        expect(item.event_recurrences).to have(1).items
        item.event_recurrences[0].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on1.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on1.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq until_on1.in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        expect(item.event_dates).to eq [ start_on1, start_on1 + 1.day, start_on1 + 2.days ]
      end
    end

    context "add and remove" do
      it do
        visit event_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name

          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            fill_in "item[event_name]", with: event_name
            fill_in_date "item[event_deadline]", with: event_deadline
            within ".event-recurrence[data-index='1']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1
            end

            click_on I18n.t("event.add_date")
            within ".event-recurrence[data-index='2']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1 + 1.week
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        expect(Event::Page.all.count).to eq 1
        item = Event::Page.all.first
        expect(item.site_id).to eq site.id
        expect(item.filename).to start_with "#{node.filename}/"
        expect(item.name).to eq name
        expect(item.event_name).to eq event_name
        expect(item.event_deadline.in_time_zone).to eq event_deadline.in_time_zone
        expect(item.event_recurrences).to have(2).items
        item.event_recurrences[0].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on1.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on1.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq start_on1.in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        item.event_recurrences[1].tap do |event_recurrence|
          start_on2 = start_on1 + 1.week
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on2.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        expect(item.event_dates).to eq [ start_on1, start_on1 + 1.week ]

        # Update
        visit event_pages_path(site: site, cid: node)
        click_on item.name
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"
        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            within ".event-recurrence[data-index='1']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1 + 2.weeks
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        item.reload
        expect(item.event_recurrences).to have(2).items
        item.event_recurrences[0].tap do |event_recurrence|
          start_on3 = start_on1 + 2.weeks
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on3.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on3.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq start_on3.in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        item.event_recurrences[1].tap do |event_recurrence|
          start_on2 = start_on1 + 1.week
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on2.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        expect(item.event_dates).to eq [ start_on1 + 1.week, start_on1 + 2.weeks ]

        # Delete
        visit event_pages_path(site: site, cid: node)
        click_on item.name
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"
        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            within ".event-recurrence[data-index='1']" do
              page.accept_confirm(I18n.t("event.confirm.delete_date")) { click_on I18n.t("ss.buttons.delete") }
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        item.reload
        expect(item.event_recurrences).to have(1).items
        item.event_recurrences[0].tap do |event_recurrence|
          start_on2 = start_on1 + 1.week
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on2.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        expect(item.event_dates).to eq [ start_on1 + 1.week ]

        # Delete All
        visit event_pages_path(site: site, cid: node)
        click_on item.name
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"
        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            fill_in "item[event_name]", with: ''
            fill_in_date "item[event_deadline]", with: nil

            within ".event-recurrence[data-index='1']" do
              page.accept_confirm(I18n.t("event.confirm.delete_date")) { click_on I18n.t("ss.buttons.delete") }
            end
            within ".event-recurrence[data-index='1']" do
              page.accept_confirm(I18n.t("event.confirm.delete_date")) { click_on I18n.t("ss.buttons.delete") }
            end
            expect(page).to have_css(".event-recurrence", count: 1)
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        item.reload
        expect(item.event_recurrences).to be_blank
        expect(item.event_dates).to be_blank
      end
    end

    context "by_days crud" do
      it do
        visit event_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name

          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            fill_in "item[event_name]", with: event_name
            fill_in_date "item[event_deadline]", with: event_deadline
            within ".event-recurrence[data-index='1']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1
              fill_in_date "item[event_recurrences][][in_until_on]", with: start_on1 + 1.week - 1.day
              # 月
              first("[name='item[event_recurrences][][in_by_days][]'][value='1']").click
              # 水
              first("[name='item[event_recurrences][][in_by_days][]'][value='3']").click
              # 金
              first("[name='item[event_recurrences][][in_by_days][]'][value='5']").click
            end

            click_on I18n.t("event.add_date")
            within ".event-recurrence[data-index='2']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1 + 1.week
              fill_in_date "item[event_recurrences][][in_until_on]", with: start_on1 + 2.weeks - 1.day
              # 火
              first("[name='item[event_recurrences][][in_by_days][]'][value='2']").click
              # 木
              first("[name='item[event_recurrences][][in_by_days][]'][value='4']").click
              # 土
              first("[name='item[event_recurrences][][in_by_days][]'][value='6']").click
            end

            click_on I18n.t("event.add_date")
            within ".event-recurrence[data-index='3']" do
              fill_in_date "item[event_recurrences][][in_start_on]", with: start_on1 + 2.weeks
              fill_in_date "item[event_recurrences][][in_until_on]", with: start_on1 + 3.weeks - 1.day
              # 日
              first("[name='item[event_recurrences][][in_by_days][]'][value='0']").click
              # 土
              first("[name='item[event_recurrences][][in_by_days][]'][value='6']").click
              # 祝
              first("[name='item[event_recurrences][][in_by_days][]'][value='holiday']").click
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        expect(Event::Page.all.count).to eq 1
        item = Event::Page.all.first
        expect(item.event_recurrences).to have(3).items
        item.event_recurrences[0].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on1.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on1.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "weekly"
          expect(event_recurrence.until_on.in_time_zone).to eq (start_on1 + 1.week - 1.day).in_time_zone
          expect(event_recurrence.by_days).to eq [1, 3, 5]
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        start_on2 = start_on1 + 1.week
        item.event_recurrences[1].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on2.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "weekly"
          expect(event_recurrence.until_on.in_time_zone).to eq (start_on2 + 1.week - 1.day).in_time_zone
          expect(event_recurrence.by_days).to eq [2, 4, 6]
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        start_on3 = start_on1 + 2.weeks
        item.event_recurrences[2].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on3.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on3.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "weekly"
          expect(event_recurrence.until_on.in_time_zone).to eq (start_on3 + 1.week - 1.day).in_time_zone
          expect(event_recurrence.by_days).to eq [0, 6]
          expect(event_recurrence.includes_holiday).to be_truthy
          expect(event_recurrence.exclude_dates).to be_blank
        end
        expect(item.event_dates).to have(9).items
        expect(item.event_dates).to include(start_on1, start_on1 + 2.days, start_on1 + 4.days)
        expect(item.event_dates).to include(start_on2 + 1.day, start_on2 + 3.days, start_on2 + 5.days)
        # 2023/2/23（木） が祝日
        expect(item.event_dates).to include(start_on3 + 3.days, start_on3 + 5.days, start_on3 + 6.days)

        # clear all
        visit event_pages_path(site: site, cid: node)
        click_on item.name
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"
        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          ensure_addon_opened "#addon-event-agents-addons-date"
          within "#addon-event-agents-addons-date" do
            within ".event-recurrence[data-index='1']" do
              0.upto(6).each do |i|
                el = first("[name='item[event_recurrences][][in_by_days][]'][value='#{i}']")
                el.click if el.checked?
              end
              first("[name='item[event_recurrences][][in_by_days][]'][value='holiday']").tap do |el|
                el.click if el.checked?
              end
            end
            within ".event-recurrence[data-index='2']" do
              0.upto(6).each do |i|
                el = first("[name='item[event_recurrences][][in_by_days][]'][value='#{i}']")
                el.click if el.checked?
              end
              first("[name='item[event_recurrences][][in_by_days][]'][value='holiday']").tap do |el|
                el.click if el.checked?
              end
            end
            within ".event-recurrence[data-index='3']" do
              0.upto(6).each do |i|
                el = first("[name='item[event_recurrences][][in_by_days][]'][value='#{i}']")
                el.click if el.checked?
              end
              first("[name='item[event_recurrences][][in_by_days][]'][value='holiday']").tap do |el|
                el.click if el.checked?
              end
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        item.reload
        expect(item.event_recurrences).to have(3).items
        item.event_recurrences[0].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on1.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on1.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq (start_on1 + 1.week - 1.day).in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        start_on2 = start_on1 + 1.week
        item.event_recurrences[1].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on2.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on2.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq (start_on2 + 1.week - 1.day).in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        start_on3 = start_on1 + 2.weeks
        item.event_recurrences[2].tap do |event_recurrence|
          expect(event_recurrence.kind).to eq "date"
          expect(event_recurrence.start_at.in_time_zone).to eq start_on3.in_time_zone
          expect(event_recurrence.end_at.in_time_zone).to eq start_on3.tomorrow.in_time_zone
          expect(event_recurrence.frequency).to eq "daily"
          expect(event_recurrence.until_on.in_time_zone).to eq (start_on3 + 1.week - 1.day).in_time_zone
          expect(event_recurrence.by_days).to be_blank
          expect(event_recurrence.includes_holiday).to be_falsey
          expect(event_recurrence.exclude_dates).to be_blank
        end
        expect(item.event_dates).to have(7 * 3).items
        expect(item.event_dates).to include(*(start_on1..(start_on1 + 3.weeks - 1.day)).to_a)
      end
    end
  end
end
