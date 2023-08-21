FactoryBot.define do
  trait :gws_attendance_time_card do
    cur_site { gws_site }
    cur_user { gws_user }
    date { Time.zone.now.beginning_of_month }
  end

  trait :with_records do
    after(:create) do |item|
      d = item.date.in_time_zone.beginning_of_month
      while d < item.date.in_time_zone.end_of_month
        if d.wday == 0 || d.wday == 6
          d += 1.day
          next
        end
        if HolidayJapan.check(d.to_date)
          d += 1.day
          next
        end

        record = item.records.where(date: d).first
        if record.blank?
          record = item.records.create(date: d)
        end
        record.enter = d.change(hour: 8, min: (0..30).to_a.sample)
        record.leave = d.change(hour: 17, min: (16..59).to_a.sample)
        record.save

        item.histories.create(date: d, field_name: 'enter', action: 'set')
        item.histories.create(date: d, field_name: 'leave', action: 'set')

        d += 1.day
      end
    end
  end

  factory :gws_attendance_time_card, class: Gws::Attendance::TimeCard, traits: [:gws_attendance_time_card]
end
