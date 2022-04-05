require 'spec_helper'

describe Event::Page, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :event_node_page, cur_site: site }
  let(:now) { Time.zone.now.change(sec: 0, usec: 0) }
  let(:today) { Time.zone.today }
  subject! do
    page = create(:event_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurrence ])
    Event::Page.find(page.id)
  end

  describe "#event_recurrences" do
    context "when event_recurrences are directly set" do
      context "kind is date" do
        context "daily single day recurrence" do
          let(:event_recurrence) do
            { kind: "date", start_at: today, frequency: "daily", until_on: today }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq today
              expect(recurr.end_at).to eq today + 1
              expect(recurr.frequency).to eq "daily"
              expect(recurr.until_on).to eq today
              expect(recurr.by_days).to be_blank
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(1).items
            expect(subject.event_dates[0]).to eq today
          end
        end

        context "daily 2 days recurrence" do
          let(:event_recurrence) do
            { kind: "date", start_at: today, frequency: "daily", until_on: today + 1.day }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq today
              expect(recurr.end_at).to eq today + 1
              expect(recurr.frequency).to eq "daily"
              expect(recurr.until_on).to eq today + 1.day
              expect(recurr.by_days).to be_blank
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates[0]).to eq today
            expect(subject.event_dates[1]).to eq today + 1.day
          end
        end

        context "weekly recurrence" do
          let(:after_1week) { today + 1.week }
          let(:event_recurrence) do
            { kind: "date", start_at: today, frequency: "weekly", until_on: after_1week - 1.day, by_days: [ 0, 1 ] }
          end
          let(:sunday_in_week) { (today..after_1week).find { |date| date.wday == 0 } }
          let(:monday_in_week) { (today..after_1week).find { |date| date.wday == 1 } }

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq today
              expect(recurr.end_at).to eq today + 1
              expect(recurr.frequency).to eq "weekly"
              expect(recurr.until_on).to eq after_1week - 1.day
              expect(recurr.by_days).to eq [ 0, 1 ]
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates).to include(sunday_in_week, monday_in_week)
          end
        end

        context "weekly recurrence with excluded dates" do
          let(:after_1week) { today + 1.week }
          let(:event_recurrence) do
            { kind: "date", start_at: today, frequency: "weekly", until_on: after_1week - 1.day,
              by_days: [ 0, 1, 2, 3, 4, 5, 6 ], exclude_dates: [ today + 1.day, today + 3.days ] }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq today
              expect(recurr.end_at).to eq today + 1
              expect(recurr.frequency).to eq "weekly"
              expect(recurr.until_on).to eq after_1week - 1.day
              expect(recurr.by_days).to eq [ 0, 1, 2, 3, 4, 5, 6 ]
              expect(recurr.exclude_dates).to eq [ today + 1.day, today + 3.days ]
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(5).items
            expect(subject.event_dates).to include(today, today + 2.days, today + 4.days, today + 5.days, today + 6.days)
          end
        end
      end

      context "kind is datetime" do
        context "daily single day recurrence" do
          let(:event_recurrence) do
            { kind: "datetime", start_at: now, end_at: now + 1.hour, frequency: "daily", until_on: today }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq now
              expect(recurr.end_at).to eq now + 1.hour
              expect(recurr.frequency).to eq "daily"
              expect(recurr.until_on).to eq today
              expect(recurr.by_days).to be_blank
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(1).items
            expect(subject.event_dates[0]).to eq today
          end
        end

        context "daily 2 days recurrence" do
          let(:event_recurrence) do
            { kind: "datetime", start_at: now, end_at: now + 1.hour, frequency: "daily", until_on: today + 1.day }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq now
              expect(recurr.end_at).to eq now + 1.hour
              expect(recurr.frequency).to eq "daily"
              expect(recurr.until_on).to eq today + 1.day
              expect(recurr.by_days).to be_blank
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates[0]).to eq today
            expect(subject.event_dates[1]).to eq today + 1.day
          end
        end

        context "weekly recurrence" do
          let(:after_1week) { today + 1.week }
          let(:event_recurrence) do
            {
              kind: "datetime", start_at: now, end_at: now + 1.hour, frequency: "weekly",
              until_on: after_1week - 1.day, by_days: [ 0, 1 ]
            }
          end
          let!(:sunday_in_week) { (today..after_1week).find { |date| date.wday == 0 } }
          let!(:monday_in_week) { (today..after_1week).find { |date| date.wday == 1 } }

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq now
              expect(recurr.end_at).to eq now + 1.hour
              expect(recurr.frequency).to eq "weekly"
              expect(recurr.until_on).to eq after_1week - 1.day
              expect(recurr.by_days).to eq [ 0, 1 ]
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates).to include(sunday_in_week, monday_in_week)
          end
        end

        context "weekly recurrence with exclude dates" do
          let(:after_1week) { today + 1.week }
          let(:event_recurrence) do
            {
              kind: "datetime", start_at: now, end_at: now + 1.hour, frequency: "weekly",
              until_on: after_1week - 1.day, by_days: [ 0, 1, 2, 3, 4, 5, 6 ],
              exclude_dates: [ today + 1.day, today + 3.days ]
            }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq event_recurrence[:kind]
              expect(recurr.start_at).to eq now
              expect(recurr.end_at).to eq now + 1.hour
              expect(recurr.frequency).to eq "weekly"
              expect(recurr.until_on).to eq after_1week - 1.day
              expect(recurr.by_days).to eq [ 0, 1, 2, 3, 4, 5, 6 ]
              expect(recurr.exclude_dates).to eq [ today + 1.day, today + 3.days ]
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(5).items
            expect(subject.event_dates).to include(*[now, now + 2.days, now + 4.days, now + 5.days, now + 6.days].map(&:to_date))
          end
        end
      end
    end

    context "when event_recurrences are set with view params" do
      context "kind is date" do
        context "daily recurrence" do
          let(:event_recurrence) do
            {
              in_update_from_view: 1, in_frequency: "daily", in_kind: "date",
              in_start_on: I18n.l(today, format: :picker), in_until_on: I18n.l(today + 1.day, format: :picker),
              in_start_time: "", in_end_time: ""
            }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq "date"
              expect(recurr.start_at).to eq today
              expect(recurr.end_at).to eq today + 1
              expect(recurr.frequency).to eq "daily"
              expect(recurr.until_on).to eq today + 1.day
              expect(recurr.by_days).to be_blank
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates[0]).to eq today
            expect(subject.event_dates[1]).to eq today + 1.day
          end
        end

        context "weekly recurrence" do
          let(:after_1week) { today + 1.week }
          let(:event_recurrence) do
            {
              in_update_from_view: 1, in_frequency: "weekly", in_kind: "date",
              in_start_on: I18n.l(today, format: :picker), in_until_on: I18n.l(after_1week - 1.day, format: :picker),
              in_start_time: "", in_end_time: "", in_by_days: [ "", "0", "1" ]
            }
          end
          let(:sunday_in_week) { (today..after_1week).find { |date| date.wday == 0 } }
          let(:monday_in_week) { (today..after_1week).find { |date| date.wday == 1 } }

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq "date"
              expect(recurr.start_at).to eq today
              expect(recurr.end_at).to eq today + 1
              expect(recurr.frequency).to eq "weekly"
              expect(recurr.until_on).to eq after_1week - 1.day
              expect(recurr.by_days).to eq [ 0, 1 ]
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates).to include(sunday_in_week, monday_in_week)
          end
        end
      end

      context "kind is datetime" do
        context "daily recurrence" do
          let(:event_recurrence) do
            {
              in_update_from_view: 1, in_frequency: "daily", in_kind: "datetime",
              in_start_on: I18n.l(today, format: :picker), in_until_on: I18n.l(today + 1.day, format: :picker),
              in_start_time: I18n.l(now, format: :zoo_hh_mm), in_end_time: I18n.l(now + 1.hour, format: :zoo_hh_mm)
            }
          end

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq "datetime"
              expect(recurr.start_at).to eq now
              expect(recurr.end_at).to eq now + 1.hour
              expect(recurr.frequency).to eq "daily"
              expect(recurr.until_on).to eq today + 1.day
              expect(recurr.by_days).to be_blank
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates[0]).to eq today
            expect(subject.event_dates[1]).to eq today + 1.day
          end
        end

        context "weekly recurrence" do
          let(:after_1week) { today + 1.week }
          let(:event_recurrence) do
            {
              in_update_from_view: 1, in_frequency: "weekly", in_kind: "datetime",
              in_start_on: I18n.l(today, format: :picker), in_until_on: I18n.l(after_1week - 1.day, format: :picker),
              in_start_time: I18n.l(now, format: :zoo_hh_mm), in_end_time: I18n.l(now + 1.hour, format: :zoo_hh_mm),
              in_by_days: [ "", "0", "1" ]
            }
          end
          let(:sunday_in_week) { (today..after_1week).find { |date| date.wday == 0 } }
          let(:monday_in_week) { (today..after_1week).find { |date| date.wday == 1 } }

          it do
            expect(subject.event_recurrences).to have(1).items
            subject.event_recurrences.first.tap do |recurr|
              expect(recurr).to be_a(Event::Extensions::Recurrence)
              expect(recurr.kind).to eq "datetime"
              expect(recurr.start_at).to eq now
              expect(recurr.start_at.utc_offset).to eq now.utc_offset
              expect(recurr.end_at).to eq now + 1.hour
              expect(recurr.end_at.utc_offset).to eq now.utc_offset
              expect(recurr.frequency).to eq "weekly"
              expect(recurr.until_on).to eq after_1week - 1.day
              expect(recurr.by_days).to eq [ 0, 1 ]
            end
            # event_recurrences をセットすると、検索用の event_dates が自動的にセットされる
            expect(subject.event_dates).to have(2).items
            expect(subject.event_dates).to include(sunday_in_week, monday_in_week)
          end
        end
      end
    end
  end
end
