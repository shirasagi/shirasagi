require 'spec_helper'

# 英語形式の日付/時刻をうまく扱えるように monkey patch を当てた。
# その monkey patch がうまく動作するかを確認する。
describe Time do
  describe ".mongoize" do
    it do
      expect(Time.mongoize(nil)).to be_nil
      expect(Time.mongoize('')).to be_nil
      expect { Time.mongoize(Object.new) }.to raise_error NoMethodError

      time = "2023/01/01 07:00".in_time_zone
      while time < "2023/12/31 23:00".in_time_zone
        expect(Time.mongoize(time)).to eq time.utc

        %i[ja en].each do |locale|
          I18n.with_locale(locale) do
            Time.mongoize(time.rfc2822).tap do |value|
              expect(value).to eq time.utc
              expect(value.class).to eq time.utc.class
              expect(value.zone).to eq time.utc.zone
            end
            expect(Time.mongoize(time.iso8601)).to eq time.utc
            expect(Time.mongoize(time.rfc3339)).to eq time.utc

            expect(Time.mongoize(I18n.l(time))).to eq time
            expect(Time.mongoize(I18n.l(time, format: :default))).to eq time.utc
            expect(Time.mongoize(I18n.l(time, format: :picker))).to eq time.utc
            expect(Time.mongoize(I18n.l(time, format: :csv))).to eq time.utc

            expect(Time.mongoize(I18n.l(time.to_date))).to eq time.change(hour: 0).utc
            expect(Time.mongoize(I18n.l(time.to_date, format: :default))).to eq time.change(hour: 0).utc
            expect(Time.mongoize(I18n.l(time.to_date, format: :picker))).to eq time.change(hour: 0).utc
            expect(Time.mongoize(I18n.l(time.to_date, format: :csv))).to eq time.change(hour: 0).utc
          end
        end

        time += 1.day
      end
    end
  end
end

describe DateTime do
  describe ".mongoize" do
    it do
      expect(DateTime.mongoize(nil)).to be_nil
      expect(DateTime.mongoize('')).to be_nil
      expect { DateTime.mongoize(Object.new) }.to raise_error NoMethodError

      time = "2023/01/01 07:00".in_time_zone
      while time < "2023/12/31 23:00".in_time_zone
        expect(DateTime.mongoize(time).in_time_zone).to eq time

        %i[ja en].each do |locale|
          I18n.with_locale(locale) do
            DateTime.mongoize(time.rfc2822).tap do |value|
              expect(value).to eq time.utc
              expect(value.class).to eq time.utc.class
              expect(value.zone).to eq time.utc.zone
            end
            expect(DateTime.mongoize(time.iso8601)).to eq time.utc
            expect(DateTime.mongoize(time.rfc3339)).to eq time.utc

            expect(DateTime.mongoize(I18n.l(time))).to eq time.utc
            expect(DateTime.mongoize(I18n.l(time, format: :default))).to eq time.utc
            expect(DateTime.mongoize(I18n.l(time, format: :picker))).to eq time.utc
            expect(DateTime.mongoize(I18n.l(time, format: :csv))).to eq time.utc

            expect(DateTime.mongoize(I18n.l(time.to_date))).to eq time.change(hour: 0).utc
            expect(DateTime.mongoize(I18n.l(time.to_date, format: :default))).to eq time.change(hour: 0).utc
            expect(DateTime.mongoize(I18n.l(time.to_date, format: :picker))).to eq time.change(hour: 0).utc
            expect(DateTime.mongoize(I18n.l(time.to_date, format: :csv))).to eq time.change(hour: 0).utc
          end
        end

        time += 1.day
      end
    end
  end
end

describe DateTime do
  describe ".mongoize" do
    it do
      expect(Date.mongoize(nil)).to be_nil
      expect(Date.mongoize('')).to be_nil
      expect { Date.mongoize(Object.new) }.to raise_error NoMethodError

      date = "2023/01/06 07:00".in_time_zone
      %i[ja en].each do |locale|
        I18n.with_locale(locale) do
          Date.mongoize(date.to_date.rfc2822).tap do |value|
            expect(value).to eq Time.utc(date.year, date.month, date.day)
            expect(value.class).to eq Time
            expect(value.zone).to eq "UTC"
          end
          expect(Date.mongoize(date.to_date.iso8601)).to eq Time.utc(date.year, date.month, date.day)
          expect(Date.mongoize(date.to_date.rfc3339)).to eq Time.utc(date.year, date.month, date.day)

          expect(Date.mongoize(I18n.l(date.to_date))).to eq Time.utc(date.year, date.month, date.day)
          expect(Date.mongoize(I18n.l(date.to_date, format: :default))).to eq Time.utc(date.year, date.month, date.day)
          expect(Date.mongoize(I18n.l(date.to_date, format: :picker))).to eq Time.utc(date.year, date.month, date.day)
          expect(Date.mongoize(I18n.l(date.to_date, format: :csv))).to eq Time.utc(date.year, date.month, date.day)

          expect(Date.mongoize(I18n.l(date))).to eq Time.utc(date.year, date.month, date.day)
          expect(Date.mongoize(I18n.l(date, format: :default))).to eq Time.utc(date.year, date.month, date.day)
          expect(Date.mongoize(I18n.l(date, format: :picker))).to eq Time.utc(date.year, date.month, date.day)
          expect(Date.mongoize(I18n.l(date, format: :csv))).to eq Time.utc(date.year, date.month, date.day)
        end
      end

      # https://jira.mongodb.org/browse/MONGOID-4460
      expect(Date.mongoize("2017-06-24")).to eq Date.mongoize("2017-06-24 00:00:00 UTC")
      expect(Date.mongoize("2017-06-24")).to eq Time.utc(2017, 6, 24)
      expect(Date.mongoize("2017-06-24 00:00:00 UTC")).to eq Time.utc(2017, 6, 24)
    end
  end
end

describe ActiveModel::Type::DateTime do
  describe "#cast" do
    it do
      expect(ActiveModel::Type::DateTime.new.cast(nil)).to be_nil
      expect(ActiveModel::Type::DateTime.new.cast('')).to be_nil
      Object.new.tap do |value|
        expect(ActiveModel::Type::DateTime.new.cast(value)).to eq value
      end

      time = "2023/01/01 07:00".in_time_zone
      while time < "2023/12/31 23:00".in_time_zone
        expect(ActiveModel::Type::DateTime.new.cast(time)).to eq time

        %i[ja en].each do |locale|
          I18n.with_locale(locale) do
            ActiveModel::Type::DateTime.new.cast(time.rfc2822).tap do |value|
              expect(value).to eq time.to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(time.iso8601).tap do |value|
              expect(value).to eq time.to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(time.rfc3339).tap do |value|
              expect(value).to eq time.to_time
              expect(value.zone).to eq "JST"
            end

            ActiveModel::Type::DateTime.new.cast(I18n.l(time)).tap do |value|
              expect(value).to eq time.to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(I18n.l(time, format: :default)).tap do |value|
              expect(value).to eq time.to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(I18n.l(time, format: :picker)).tap do |value|
              expect(value).to eq time.to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(I18n.l(time, format: :csv)).tap do |value|
              expect(value).to eq time.to_time
              expect(value.zone).to eq "JST"
            end

            ActiveModel::Type::DateTime.new.cast(I18n.l(time.to_date)).tap do |value|
              expect(value).to eq time.change(hour: 0).to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(I18n.l(time.to_date, format: :default)).tap do |value|
              expect(value).to eq time.change(hour: 0).to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(I18n.l(time.to_date, format: :picker)).tap do |value|
              expect(value).to eq time.change(hour: 0).to_time
              expect(value.zone).to eq "JST"
            end
            ActiveModel::Type::DateTime.new.cast(I18n.l(time.to_date, format: :csv)).tap do |value|
              expect(value).to eq time.change(hour: 0).to_time
              expect(value.zone).to eq "JST"
            end
          end
        end

        time += 1.day
      end
    end
  end
end

describe ActiveModel::Type::Date do
  describe "#cast" do
    it do
      expect(ActiveModel::Type::Date.new.cast(nil)).to be_nil
      expect(ActiveModel::Type::Date.new.cast('')).to be_nil
      Object.new.tap do |value|
        expect(ActiveModel::Type::Date.new.cast(value)).to eq value
      end

      time = "2023/01/01 07:00".in_time_zone
      while time < "2023/12/31 23:00".in_time_zone
        expect(ActiveModel::Type::Date.new.cast(time)).to eq time.to_date

        %i[ja en].each do |locale|
          I18n.with_locale(locale) do
            ActiveModel::Type::Date.new.cast(time.rfc2822).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(time.iso8601).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(time.rfc3339).tap do |value|
              expect(value).to eq time.to_date
            end

            ActiveModel::Type::Date.new.cast(I18n.l(time)).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(I18n.l(time, format: :default)).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(I18n.l(time, format: :picker)).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(I18n.l(time, format: :csv)).tap do |value|
              expect(value).to eq time.to_date
            end

            ActiveModel::Type::Date.new.cast(I18n.l(time.to_date)).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(I18n.l(time.to_date, format: :default)).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(I18n.l(time.to_date, format: :picker)).tap do |value|
              expect(value).to eq time.to_date
            end
            ActiveModel::Type::Date.new.cast(I18n.l(time.to_date, format: :csv)).tap do |value|
              expect(value).to eq time.to_date
            end
          end
        end

        time += 1.day
      end
    end
  end
end

describe Gws::Schedule::Plan do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  describe "#start_at" do
    it do
      start_at = "2023/01/06 15:00".in_time_zone

      plan = I18n.with_locale(:en) do
        Gws::Schedule::Plan.create!(
          cur_site: site, name: unique_id, member_ids: [ user.id ],
          start_at: I18n.l(start_at, format: :picker),
          end_at: I18n.l(start_at + 1.hour, format: :picker)
        )
      end

      Gws::Schedule::Plan.find(plan.id).tap do |plan|
        expect(plan.start_at.in_time_zone).to eq start_at
      end
    end
  end

  describe "#start_on" do
    it do
      start_on = "2023/01/06 15:00".in_time_zone.to_date

      plan = I18n.with_locale(:en) do
        Gws::Schedule::Plan.create!(
          cur_site: site, name: unique_id, member_ids: [ user.id ],
          allday: "allday",
          start_on: I18n.l(start_on, format: :picker),
          end_on: I18n.l(start_on + 1.day, format: :picker)
        )
      end

      Gws::Schedule::Plan.find(plan.id).tap do |plan|
        expect(plan.start_on.in_time_zone.to_date).to eq start_on
      end
    end
  end
end

describe Gws::HistoryDownloadParam do
  it do
    time = "2023/01/06 15:00".in_time_zone
    I18n.with_locale(:ja) do
      param = Gws::HistoryDownloadParam.new(from: I18n.l(time, format: :picker))
      expect(param.from).to eq time.to_time
      expect(param.from.iso8601).to eq time.to_time.iso8601
    end
    I18n.with_locale(:en) do
      param = Gws::HistoryDownloadParam.new(from: I18n.l(time, format: :picker))
      expect(param.from).to eq time.to_time
    end

    date = "2023/01/06 15:00".in_time_zone.to_date
    I18n.with_locale(:ja) do
      param = Gws::HistoryDownloadParam.new(from: I18n.l(date, format: :picker))
      expect(param.from).to eq date.to_time
      expect(param.from.iso8601).to eq date.to_time.iso8601
    end
    I18n.with_locale(:en) do
      param = Gws::HistoryDownloadParam.new(from: I18n.l(date, format: :picker))
      expect(param.from).to eq date.to_time
    end
  end
end
