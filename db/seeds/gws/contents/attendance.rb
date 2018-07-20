puts "# attendance/time_card"

def create_time_card(site, user, date)
  time_card = Gws::Attendance::TimeCard.site(site).user(user).where(date: date.beginning_of_month).first_or_create
  time_card.cur_site = site
  time_card.cur_user = user
  time_card.save

  d = date.beginning_of_month
  while d < date.end_of_month && d < @now.beginning_of_day
    if d.wday == 0 || d.wday == 6
      d += 1.day
      next
    end
    if HolidayJapan.check(d.to_date)
      d += 1.day
      next
    end

    record = time_card.records.where(date: d).first
    if record.blank?
      record = time_card.records.create(date: d)
    end
    record.enter = d.change(hour: 8, min: (0..30).to_a.sample)
    record.leave = d.change(hour: 17, min: (16..59).to_a.sample)
    record.save

    time_card.histories.create(date: d, field_name: 'enter', action: 'set')
    time_card.histories.create(date: d, field_name: 'leave', action: 'set')

    d += 1.day
  end
end

def create_time_cards(site, date)
  Gws::User.site(site).active.each do |user|
    create_time_card(site, user, date)
  end
end

def create_time_cards_3months(site)
  now = Time.zone.now.beginning_of_month
  (0..2).each do |i|
    create_time_cards(site, now - i.months)
  end
end

Gws::Group.all.active.each do |group|
  next unless group.root?

  create_time_cards_3months(group)
end
