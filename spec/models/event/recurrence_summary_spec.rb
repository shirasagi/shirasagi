require 'spec_helper'

describe Event, dbscope: :example do
  let(:now) { Time.zone.now.change(sec: 0, usec: 0) }

  describe ".recurrence_summary" do
    subject! { Event.recurrence_summary(recurrences) }

    context "single daily recurrence" do
      let(:recurrence) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: now, end_at: now + 45.minutes, frequency: "daily", until_on: now.to_date)
      end
      let(:recurrences) { [ recurrence ] }

      it do
        expected = [
          I18n.l(now.to_date, format: :full),
          Event::DATE_TIME_SEPARATOR,
          I18n.l(now, format: :h_mm), Event::START_AND_END_TIME_SEPARATOR, I18n.l(now + 45.minutes, format: :h_mm)
        ].join
        expect(subject).to eq expected
      end
    end

    context "2 daily recurrences on same date" do
      let(:start_at1) { now.change(hour: 10) }
      let(:recurrence1) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: start_at1, end_at: start_at1 + 45.minutes, frequency: "daily", until_on: now.to_date)
      end
      let(:start_at2) { now.change(hour: 14) }
      let(:recurrence2) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: start_at2, end_at: start_at2 + 45.minutes, frequency: "daily", until_on: now.to_date)
      end
      let(:recurrences) { [ recurrence1, recurrence2 ] }

      it do
        expected = [
          I18n.l(start_at1.to_date, format: :full),
          Event::DATE_TIME_SEPARATOR,
          I18n.l(start_at1, format: :h_mm), Event::START_AND_END_TIME_SEPARATOR,
          "／",
          I18n.l(start_at2, format: :h_mm), Event::START_AND_END_TIME_SEPARATOR
        ].join
        expect(subject).to eq expected
      end
    end

    context "2 daily recurrences on same month" do
      let(:start_at1) { now.change(day: 16, hour: 10) }
      let(:recurrence1) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: start_at1, end_at: start_at1 + 45.minutes, frequency: "daily", until_on: start_at1.to_date)
      end
      let(:start_at2) { start_at1 + 7.days }
      let(:recurrence2) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: start_at2, end_at: start_at2 + 45.minutes, frequency: "daily", until_on: start_at2.to_date)
      end
      let(:recurrences) { [ recurrence1, recurrence2 ] }

      it do
        expected = [
          I18n.l(start_at1.to_date, format: :full),
          I18n.l(start_at2.to_date, format: "%1d日 (%a)")
        ].join(" , ")
        expect(subject).to eq expected
      end
    end

    context "2 daily recurrences on same year" do
      let(:start_at1) { now.change(mon: 7, day: 16, hour: 10) }
      let(:recurrence1) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: start_at1, end_at: start_at1 + 45.minutes, frequency: "daily", until_on: start_at1.to_date)
      end
      let(:start_at2) { start_at1 + 1.month }
      let(:recurrence2) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: start_at2, end_at: start_at2 + 45.minutes, frequency: "daily", until_on: start_at2.to_date)
      end
      let(:recurrences) { [ recurrence1, recurrence2 ] }

      it do
        expected = [
          I18n.l(start_at1.to_date, format: :full),
          I18n.l(start_at2.to_date, format: "%1m月%1d日 (%a)")
        ].join(" , ")
        expect(subject).to eq expected
      end
    end

    context "long term daily recurrence" do
      let(:recurrence1) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: "2022/03/12 10:00", end_at: "2022/03/12 17:00", frequency: "daily", until_on: "2022/05/15")
      end
      let(:recurrences) { [ recurrence1 ] }

      it do
        expected = [
          I18n.l("2022/03/12".in_time_zone.to_date, format: :full),
          I18n.t("ss.wave_dash"),
          I18n.l("2022/05/15".in_time_zone.to_date, format: "%1m月%1d日 (%a)"),
          Event::DATE_TIME_SEPARATOR,
          "10:00",
          I18n.t("ss.wave_dash"),
          "17:00"
        ].join
        expect(subject).to eq expected
      end
    end

    context "single weekly recurrence on saturday" do
      let(:recurrence1) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: "2022/04/01 15:00", end_at: "2022/04/01 15:45",
          frequency: "weekly", until_on: "2023/03/31", by_days: [ 6 ])
      end
      let(:recurrences) { [ recurrence1 ] }

      it do
        expected = [
          "【",
          I18n.l("2022/04/01".in_time_zone.to_date, format: :full),
          I18n.t("ss.wave_dash"),
          I18n.l("2023/03/31".in_time_zone.to_date, format: :full),
          "】",
          "毎週土曜日"
        ].join
        expect(subject).to eq expected
      end
    end

    context "saturday weekly recurrence and sunday weekly recurrence" do
      let(:recurrence1) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: "2022/04/01 15:00", end_at: "2022/04/01 15:45",
          frequency: "weekly", until_on: "2023/03/31", by_days: [ 6 ])
      end
      let(:recurrence2) do
        Event::Extensions::Recurrence.demongoize(
          kind: "datetime", start_at: "2022/04/01 11:00", end_at: "2022/04/01 11:45",
          frequency: "weekly", until_on: "2023/03/31", by_days: [ 0 ])
      end
      let(:recurrences) { [ recurrence1, recurrence2 ] }

      it do
        expected = [
          "【",
          I18n.l("2022/04/01".in_time_zone.to_date, format: :full),
          I18n.t("ss.wave_dash"),
          I18n.l("2023/03/31".in_time_zone.to_date, format: :full),
          "】",
          "毎週土日"
        ].join
        expect(subject).to eq expected
      end
    end
  end
end
