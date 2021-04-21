require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  before { login_gws_user }

  context "with plan" do
    let!(:now) { Time.zone.now.change(hour: 9) }
    let!(:csv_file) do
      tmpfile(extname: ".csv", binary: true) do |f|
        enum = Gws::Schedule::PlanCsv::Exporter.enum_csv([ plan_to_csv ], site: site, user: user, model: Gws::Schedule::Plan)
        enum.each do |csv|
          f.write csv
        end
      end
    end

    before do
      Gws::Schedule::Plan.all.destroy_all

      visit gws_schedule_csv_path(site: site)
      within "form#import_form" do
        attach_file "item[in_file]", csv_file
        page.accept_confirm do
          click_on I18n.t("ss.import")
        end
      end
    end

    context "with minimal required fields" do
      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id]
        )
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
        end
      end
    end

    context "with basic" do
      let!(:category0) { create :gws_schedule_category, order: 1 }
      let!(:category1) { create :gws_schedule_category, name: category0.name, order: 2 }
      let!(:priority) { (1..5).to_a.sample.to_s }

      context "allday is blank" do
        let!(:plan_to_csv) do
          Gws::Schedule::Plan.create!(
            cur_site: site, cur_user: user,
            name: unique_id, start_at: now, end_at: now + 1.hour, category: category1, priority: priority, color: unique_id,
            member_ids: [user.id]
          )
        end

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_at).to eq plan_to_csv.start_at
            expect(plan.end_at).to eq plan_to_csv.end_at
            # if there are same name categories, first order one is taken
            expect(plan.category_id).to eq category0.id
            expect(plan.priority).to eq plan_to_csv.priority
            expect(plan.color).to eq plan_to_csv.color
            expect(plan.member_ids).to include(user.id)
          end
        end
      end

      context "allday is 'allday'" do
        let!(:plan_to_csv) do
          Gws::Schedule::Plan.create!(
            cur_site: site, cur_user: user, name: unique_id,
            start_at: now, end_at: now + 1.hour, start_on: now.tomorrow.beginning_of_day, end_on: now.tomorrow.beginning_of_day, allday: "allday",
            category: category1, priority: priority, color: unique_id,
            member_ids: [user.id]
          )
        end

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_on).to eq plan_to_csv.start_on
            expect(plan.end_on).to eq plan_to_csv.end_on
            # if there are same name categories, first order one is taken
            expect(plan.category_id).to eq category0.id
            expect(plan.priority).to eq plan_to_csv.priority
            expect(plan.color).to eq plan_to_csv.color
            expect(plan.member_ids).to include(user.id)
          end
        end
      end
    end

    context "with notify_setting" do
      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
          notify_state: "enabled"
        )
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.notify_state).to eq "enabled"
        end

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context "with markdown" do
      context "when text_type is plain" do
        let(:text) { unique_id * rand(2..5) }
        let!(:plan_to_csv) do
          Gws::Schedule::Plan.create!(
            cur_site: site, cur_user: user,
            name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
            text_type: "plain", text: text
          )
        end

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_at).to eq plan_to_csv.start_at
            expect(plan.end_at).to eq plan_to_csv.end_at
            expect(plan.member_ids).to include(user.id)
            expect(plan.text_type).to eq "plain"
            expect(plan.text).to eq text
          end
        end
      end

      context "when text_type is markdown" do
        let(:text) { unique_id * rand(2..5) }
        let!(:plan_to_csv) do
          Gws::Schedule::Plan.create!(
            cur_site: site, cur_user: user,
            name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
            text_type: "markdown", text: text
          )
        end

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_at).to eq plan_to_csv.start_at
            expect(plan.end_at).to eq plan_to_csv.end_at
            expect(plan.member_ids).to include(user.id)
            expect(plan.text_type).to eq "markdown"
            expect(plan.text).to eq text
          end
        end
      end
    end

    context "with member" do
      let!(:user1) { create :gws_user }

      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user2) { create :gws_user, group_ids: [ group1.id ] }

      let!(:user3) { create :gws_user }

      let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user4) { create :gws_user, group_ids: [ group2.id ] }

      let(:custom_group1) { create :gws_custom_group, member_ids: [ user3.id ], member_group_ids: [ group2.id ] }

      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: now, end_at: now + 1.hour,
          member_ids: [ user1.id ], member_group_ids: [ group1.id ], member_custom_group_ids: [ custom_group1.id ]
        )
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user1.id)
          expect(plan.member_group_ids).to include(group1.id)
          expect(plan.member_custom_group_ids).to include(custom_group1.id)
        end
      end
    end

    context "with schedule_attendance" do
      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
          attendance_check_state: "enabled"
        )
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.attendance_check_state).to eq "enabled"
        end
      end
    end

    context "with schedule_approval" do
      let!(:user1) { create :gws_user }
      let!(:user2) { create :gws_user }
      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
          notify_state: "enabled", approval_member_ids: [ user1.id, user2.id ]
        )
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.approval_member_ids).to include(user1.id, user2.id)
        end

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context "with readable_setting" do
      let!(:user1) { create :gws_user }

      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user2) { create :gws_user, group_ids: [ group1.id ] }

      let!(:user3) { create :gws_user }

      let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user4) { create :gws_user, group_ids: [ group2.id ] }

      let(:custom_group1) { create :gws_custom_group, member_ids: [ user3.id ], member_group_ids: [ group2.id ] }

      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
          readable_setting_range: readable_setting_range,
          readable_member_ids: [ user1.id ], readable_group_ids: [ group1.id ], readable_custom_group_ids: [ custom_group1.id ]
        )
      end

      context "when readable_setting_range is public" do
        let(:readable_setting_range) { "public" }

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_at).to eq plan_to_csv.start_at
            expect(plan.end_at).to eq plan_to_csv.end_at
            expect(plan.member_ids).to include(user.id)
            expect(plan.readable_setting_range).to eq "public"
            expect(plan.readable_member_ids).to be_blank
            expect(plan.readable_group_ids).to be_blank
            expect(plan.readable_custom_group_ids).to be_blank
          end
        end
      end

      context "when readable_setting_range is select" do
        let(:readable_setting_range) { "select" }

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_at).to eq plan_to_csv.start_at
            expect(plan.end_at).to eq plan_to_csv.end_at
            expect(plan.member_ids).to include(user.id)
            expect(plan.readable_setting_range).to eq "select"
            expect(plan.readable_member_ids).to include(user1.id)
            expect(plan.readable_group_ids).to include(group1.id)
            expect(plan.readable_custom_group_ids).to include(custom_group1.id)
          end
        end
      end

      context "when readable_setting_range is private" do
        let(:readable_setting_range) { "private" }

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_at).to eq plan_to_csv.start_at
            expect(plan.end_at).to eq plan_to_csv.end_at
            expect(plan.member_ids).to include(user.id)
            expect(plan.readable_setting_range).to eq "private"
            expect(plan.readable_member_ids).to include(user.id)
            expect(plan.readable_group_ids).to be_blank
            expect(plan.readable_custom_group_ids).to be_blank
          end
        end
      end

      context "when readable_setting_range is blank" do
        let(:readable_setting_range) { "" }

        it do
          expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
          expect(Gws::Schedule::Plan.all.count).to eq 1
          Gws::Schedule::Plan.all.first.tap do |plan|
            expect(plan.site_id).to eq plan_to_csv.site_id
            expect(plan.name).to eq plan_to_csv.name
            expect(plan.start_at).to eq plan_to_csv.start_at
            expect(plan.end_at).to eq plan_to_csv.end_at
            expect(plan.member_ids).to include(user.id)
            expect(plan.readable_setting_range).to be_blank
            expect(plan.readable_member_ids).to include(user1.id)
            expect(plan.readable_group_ids).to include(group1.id)
            expect(plan.readable_custom_group_ids).to include(custom_group1.id)
          end
        end
      end
    end

    context "with group_permission" do
      let!(:user1) { create :gws_user }

      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user2) { create :gws_user, group_ids: [ group1.id ] }

      let!(:user3) { create :gws_user }

      let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user4) { create :gws_user, group_ids: [ group2.id ] }

      let(:custom_group1) { create :gws_custom_group, member_ids: [ user3.id ], member_group_ids: [ group2.id ] }

      let(:permission_level) { rand(1..3) }

      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
          permission_level: permission_level,
          user_ids: [ user.id, user1.id ], group_ids: [ group1.id ], custom_group_ids: [ custom_group1.id ]
        )
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.permission_level).to eq permission_level
          expect(plan.user_ids).to include(user.id, user1.id)
          expect(plan.group_ids).to include(group1.id)
          expect(plan.custom_group_ids).to include(custom_group1.id)
        end
      end
    end
  end
end
