require 'spec_helper'

describe Event::IcalHelper, type: :helper, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :event_node_page, cur_site: site }
  let!(:category) { create :category_node_page, cur_site: site, cur_node: node }
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let(:recurrences) { [ recurrence ] }
  let!(:page) do
    create :event_page, cur_site: site, cur_node: node, category_ids: [ category.id ], event_recurrences: recurrences
  end

  context "kind is date" do
    context "daily single day recurrence" do
      let(:recurrence) do
        { kind: "date", start_at: today, frequency: "daily", until_on: today }
      end

      it do
        data = helper.event_to_ical([ page ], site: site, node: node)
        ical = ::Icalendar::Calendar.parse(StringIO.new(data))
        expect(ical).to be_present
        expect(ical).to have(1).items
        ical.first.tap do |calendar|
          expect(calendar.x_wr_calname).to eq [ node.name ]
          expect(calendar.x_wr_timezone).to eq [ Time.zone.tzinfo.identifier ]
          expect(calendar.events).to have(1).items
          calendar.events.first.tap do |event|
            expect(event.uid).to be_present
            expect(event.last_modified.in_time_zone.change(usec: 0)).to eq page.updated.in_time_zone.change(usec: 0)
            expect(event.url.to_s).to eq page.ical_link
            expect(event.summary).to eq page.event_name
            expect(event.description).to eq page.content
            expect(event.location).to eq page.venue
            expect(event.contact).to eq [ page.contact ]
            expect(event.categories).to eq [ category.name ]
            expect(event.dtstart).to eq today
            expect(event.dtend).to eq today + 1.day
            expect(event.rdate).to be_blank
            expect(event.rrule).to be_blank
            expect(event.exdate).to be_blank
            expect(event.x_shirasagi_schedule).to eq [ page.schedule ]
            expect(event.x_shirasagi_relatedurl).to eq [ page.related_url ]
            expect(event.x_shirasagi_cost).to eq [ page.cost ]
            expect(event.x_shirasagi_released[0].in_time_zone).to eq page.released.in_time_zone.change(usec: 0)
            expect(event.x_shirasagi_parent_uid).to be_blank
          end
        end
      end
    end

    context "daily 2 days recurrence" do
      let(:recurrence) do
        { kind: "date", start_at: today, frequency: "daily", until_on: today + 1.day }
      end

      it do
        data = helper.event_to_ical([ page ], site: site, node: node)
        ical = ::Icalendar::Calendar.parse(StringIO.new(data))
        expect(ical).to be_present
        expect(ical).to have(1).items
        ical.first.tap do |calendar|
          expect(calendar.x_wr_calname).to eq [ node.name ]
          expect(calendar.x_wr_timezone).to eq [ Time.zone.tzinfo.identifier ]
          expect(calendar.events).to have(1).items
          calendar.events.first.tap do |event|
            expect(event.uid).to be_present
            expect(event.last_modified.in_time_zone.change(usec: 0)).to eq page.updated.in_time_zone.change(usec: 0)
            expect(event.url.to_s).to eq page.ical_link
            expect(event.summary).to eq page.event_name
            expect(event.description).to eq page.content
            expect(event.location).to eq page.venue
            expect(event.contact).to eq [ page.contact ]
            expect(event.categories).to eq [ category.name ]
            expect(event.dtstart).to eq today
            expect(event.dtend).to eq today + 1.day
            expect(event.rdate).to be_blank
            expect(event.rrule).to have(1).items
            event.rrule.first.tap do |recur|
              expect(recur.frequency).to eq recurrence[:frequency].upcase
              expect(recur.until.in_time_zone).to eq recurrence[:until_on].in_time_zone
              expect(recur.count).to be_blank
              expect(recur.by_second).to be_blank
              expect(recur.by_minute).to be_blank
              expect(recur.by_hour).to be_blank
              expect(recur.by_day).to be_blank
              expect(recur.by_month_day).to be_blank
              expect(recur.by_year_day).to be_blank
              expect(recur.by_week_number).to be_blank
              expect(recur.by_month).to be_blank
              expect(recur.by_set_position).to be_blank
              expect(recur.week_start).to be_blank
            end
            expect(event.exdate).to be_blank
            expect(event.x_shirasagi_schedule).to eq [ page.schedule ]
            expect(event.x_shirasagi_relatedurl).to eq [ page.related_url ]
            expect(event.x_shirasagi_cost).to eq [ page.cost ]
            expect(event.x_shirasagi_released[0].in_time_zone).to eq page.released.in_time_zone.change(usec: 0)
            expect(event.x_shirasagi_parent_uid).to be_blank
          end
        end
      end
    end

    context "weekly recurrence with excluded dates" do
      let(:after_1week) { today + 1.week }
      let(:recurrence) do
        { kind: "date", start_at: today, frequency: "weekly", until_on: after_1week - 1.day,
          by_days: [ 0, 1, 2, 3, 4, 5, 6 ], exclude_dates: [ today + 1.day, today + 3.days ] }
      end

      it do
        data = helper.event_to_ical([ page ], site: site, node: node)
        ical = ::Icalendar::Calendar.parse(StringIO.new(data))
        expect(ical).to be_present
        expect(ical).to have(1).items
        ical.first.tap do |calendar|
          expect(calendar.x_wr_calname).to eq [ node.name ]
          expect(calendar.x_wr_timezone).to eq [ Time.zone.tzinfo.identifier ]
          expect(calendar.events).to have(1).items
          calendar.events.first.tap do |event|
            expect(event.uid).to be_present
            expect(event.last_modified.in_time_zone.change(usec: 0)).to eq page.updated.in_time_zone.change(usec: 0)
            expect(event.url.to_s).to eq page.ical_link
            expect(event.summary).to eq page.event_name
            expect(event.description).to eq page.content
            expect(event.location).to eq page.venue
            expect(event.contact).to eq [ page.contact ]
            expect(event.categories).to eq [ category.name ]
            expect(event.dtstart).to eq today
            expect(event.dtend).to eq today + 1.day
            expect(event.rdate).to be_blank
            expect(event.rrule).to have(1).items
            event.rrule.first.tap do |recur|
              expect(recur.frequency).to eq recurrence[:frequency].upcase
              expect(recur.until.in_time_zone).to eq recurrence[:until_on].in_time_zone
              expect(recur.count).to be_blank
              expect(recur.by_second).to be_blank
              expect(recur.by_minute).to be_blank
              expect(recur.by_hour).to be_blank
              expect(recur.by_day).to eq(recurrence[:by_days].map { |i| Event::Page::IcalImporter::ICAL_WEEKDAYS[i] })
              expect(recur.by_month_day).to be_blank
              expect(recur.by_year_day).to be_blank
              expect(recur.by_week_number).to be_blank
              expect(recur.by_month).to be_blank
              expect(recur.by_set_position).to be_blank
              expect(recur.week_start).to be_blank
            end
            expect(event.exdate).to eq recurrence[:exclude_dates]
            expect(event.x_shirasagi_schedule).to eq [ page.schedule ]
            expect(event.x_shirasagi_relatedurl).to eq [ page.related_url ]
            expect(event.x_shirasagi_cost).to eq [ page.cost ]
            expect(event.x_shirasagi_released[0].in_time_zone).to eq page.released.in_time_zone.change(usec: 0)
            expect(event.x_shirasagi_parent_uid).to be_blank
          end
        end
      end
    end

    context "weekly recurrence with national holidays" do
      let(:start_at) { "2022/04/01" }
      let(:until_on) { "2022/04/30" }
      let(:recurrence) do
        { kind: "date", start_at: start_at, frequency: "weekly", until_on: until_on, includes_holiday: true }
      end

      it do
        data = helper.event_to_ical([ page ], site: site, node: node)
        ical = ::Icalendar::Calendar.parse(StringIO.new(data))
        expect(ical).to be_present
        expect(ical).to have(1).items
        ical.first.tap do |calendar|
          expect(calendar.x_wr_calname).to eq [ node.name ]
          expect(calendar.x_wr_timezone).to eq [ Time.zone.tzinfo.identifier ]
          expect(calendar.events).to have(1).items
          calendar.events.first.tap do |event|
            expect(event.uid).to be_present
            expect(event.last_modified.in_time_zone.change(usec: 0)).to eq page.updated.in_time_zone.change(usec: 0)
            expect(event.url.to_s).to eq page.ical_link
            expect(event.summary).to eq page.event_name
            expect(event.description).to eq page.content
            expect(event.location).to eq page.venue
            expect(event.contact).to eq [ page.contact ]
            expect(event.categories).to eq [ category.name ]
            expect(event.dtstart).to eq start_at.in_time_zone.to_date
            expect(event.dtend).to eq start_at.in_time_zone.to_date + 1.day
            expect(event.rdate).to eq [ Time.zone.parse("2022/04/29").to_date ]
            expect(event.rrule).to have(1).items
            event.rrule.first.tap do |recur|
              expect(recur.frequency).to eq recurrence[:frequency].upcase
              expect(recur.until.in_time_zone).to eq recurrence[:until_on].in_time_zone
              expect(recur.count).to be_blank
              expect(recur.by_second).to be_blank
              expect(recur.by_minute).to be_blank
              expect(recur.by_hour).to be_blank
              expect(recur.by_day).to eq Event::Page::IcalImporter::ICAL_WEEKDAYS
              expect(recur.by_month_day).to be_blank
              expect(recur.by_year_day).to be_blank
              expect(recur.by_week_number).to be_blank
              expect(recur.by_month).to be_blank
              expect(recur.by_set_position).to be_blank
              expect(recur.week_start).to be_blank
            end
            expect(event.exdate).to be_blank
            expect(event.x_shirasagi_schedule).to eq [ page.schedule ]
            expect(event.x_shirasagi_relatedurl).to eq [ page.related_url ]
            expect(event.x_shirasagi_cost).to eq [ page.cost ]
            expect(event.x_shirasagi_released[0].in_time_zone).to eq page.released.in_time_zone.change(usec: 0)
            expect(event.x_shirasagi_parent_uid).to be_blank
          end
        end
      end
    end

    context "multiple weekly recurrence is specified" do
      let(:recurrence1) do
        { kind: "date", start_at: "2022/05/06", frequency: "weekly", until_on: "2022/05/08", by_days: [ 0, 5, 6 ] }
      end
      let(:recurrence2) do
        { kind: "date", start_at: "2022/05/13", frequency: "weekly", until_on: "2022/05/15", by_days: [ 0, 5, 6 ] }
      end
      let(:recurrences) { [ recurrence1, recurrence2 ] }

      it do
        data = helper.event_to_ical([ page ], site: site, node: node)
        ical = ::Icalendar::Calendar.parse(StringIO.new(data))
        expect(ical).to be_present
        expect(ical).to have(1).items
        ical.first.tap do |calendar|
          expect(calendar.x_wr_calname).to eq [ node.name ]
          expect(calendar.x_wr_timezone).to eq [ Time.zone.tzinfo.identifier ]
          expect(calendar.events).to have(2).items
          calendar.events[0].tap do |event|
            expect(event.uid).to be_present
            expect(event.last_modified.in_time_zone.change(usec: 0)).to eq page.updated.in_time_zone.change(usec: 0)
            expect(event.url.to_s).to eq page.ical_link
            expect(event.summary).to eq page.event_name
            expect(event.description).to eq page.content
            expect(event.location).to eq page.venue
            expect(event.contact).to eq [ page.contact ]
            expect(event.categories).to eq [ category.name ]
            expect(event.dtstart).to eq "2022/05/06".in_time_zone.to_date
            expect(event.dtend).to eq "2022/05/06".in_time_zone.to_date + 1.day
            expect(event.rdate).to be_blank
            expect(event.rrule).to have(1).items
            event.rrule.first.tap do |recur|
              expect(recur.frequency).to eq "WEEKLY"
              expect(recur.until.in_time_zone).to eq "2022/05/08".in_time_zone
              expect(recur.count).to be_blank
              expect(recur.by_second).to be_blank
              expect(recur.by_minute).to be_blank
              expect(recur.by_hour).to be_blank
              expect(recur.by_day).to eq %w(SU FR SA)
              expect(recur.by_month_day).to be_blank
              expect(recur.by_year_day).to be_blank
              expect(recur.by_week_number).to be_blank
              expect(recur.by_month).to be_blank
              expect(recur.by_set_position).to be_blank
              expect(recur.week_start).to be_blank
            end
            expect(event.exdate).to be_blank
            expect(event.x_shirasagi_schedule).to eq [ page.schedule ]
            expect(event.x_shirasagi_relatedurl).to eq [ page.related_url ]
            expect(event.x_shirasagi_cost).to eq [ page.cost ]
            expect(event.x_shirasagi_released[0].in_time_zone).to eq page.released.in_time_zone.change(usec: 0)
            expect(event.x_shirasagi_parent_uid).to be_blank
          end

          calendar.events[1].tap do |event|
            expect(event.uid).to be_present
            expect(event.uid).not_to eq calendar.events[0].uid
            expect(event.dtstart).to eq "2022/05/13".in_time_zone.to_date
            expect(event.dtend).to eq "2022/05/13".in_time_zone.to_date + 1.day
            expect(event.rrule).to have(1).items
            event.rrule.first.tap do |recur|
              expect(recur.frequency).to eq "WEEKLY"
              expect(recur.until.in_time_zone).to eq "2022/05/15".in_time_zone
              expect(recur.by_day).to eq %w(SU FR SA)
            end
            expect(event.x_shirasagi_parent_uid).to eq [ calendar.events[0].uid ]
          end
        end
      end
    end
  end

  context "with datetime" do
    context "single daily recurrence" do
      let(:recurrence) do
        { kind: "datetime", start_at: now, end_at: now + 45.minutes, frequency: "daily", until_on: now.to_date }
      end

      it do
        data = helper.event_to_ical([ page ], site: site, node: node)
        ical = ::Icalendar::Calendar.parse(StringIO.new(data))
        expect(ical).to be_present
        expect(ical).to have(1).items
        ical.first.tap do |calendar|
          expect(calendar.x_wr_calname).to eq [ node.name ]
          expect(calendar.x_wr_timezone).to eq [ Time.zone.tzinfo.identifier ]
          calendar.events.first.tap do |event|
            expect(event.uid).to be_present
            # expect(event.recurrence_id).to be_present
            expect(event.last_modified.in_time_zone.change(usec: 0)).to eq page.updated.in_time_zone.change(usec: 0)
            expect(event.url.to_s).to eq page.ical_link
            expect(event.summary).to eq page.event_name
            expect(event.description).to eq page.content
            expect(event.location).to eq page.venue
            expect(event.contact).to eq [ page.contact ]
            expect(event.categories).to eq [ category.name ]
            expect(event.dtstart).to eq now
            expect(event.dtend).to eq now + 45.minutes
            expect(event.rdate).to be_blank
            expect(event.rrule).to be_blank
            expect(event.exdate).to be_blank
            expect(event.x_shirasagi_schedule).to eq [ page.schedule ]
            expect(event.x_shirasagi_relatedurl).to eq [ page.related_url ]
            expect(event.x_shirasagi_cost).to eq [ page.cost ]
            expect(event.x_shirasagi_released[0].in_time_zone).to eq page.released.in_time_zone.change(usec: 0)
            expect(event.x_shirasagi_parent_uid).to be_blank
          end
        end
      end
    end
  end
end
