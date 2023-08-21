require 'spec_helper'

describe SS::Duration do
  describe ".parse" do
    context "with valid durations" do
      it do
        expect(SS::Duration.parse("1.year")).to eq 1.year
        expect(SS::Duration.parse("2.years")).to eq 2.years
        expect(SS::Duration.parse("1.month")).to eq 1.month
        expect(SS::Duration.parse("2.months")).to eq 2.months
        expect(SS::Duration.parse("1.day")).to eq 1.day
        expect(SS::Duration.parse("2.days")).to eq 2.days
        expect(SS::Duration.parse("1.hour")).to eq 1.hour
        expect(SS::Duration.parse("2.hours")).to eq 2.hours
        expect(SS::Duration.parse("1.minute")).to eq 1.minute
        expect(SS::Duration.parse("2.minutes")).to eq 2.minutes
        expect(SS::Duration.parse("1.second")).to eq 1.second
        expect(SS::Duration.parse("2.seconds")).to eq 2.seconds
      end
    end

    context "with invalid unit" do
      it do
        expect { SS::Duration.parse("1.decade") }.to raise_error RuntimeError, "malformed duration: 1.decade"
      end
    end

    context "with non-number" do
      it do
        expect { SS::Duration.parse("hello.days") }.to raise_error RuntimeError, "malformed duration: hello.days"
      end
    end

    context "when unit is missing" do
      it do
        expect(SS::Duration.parse("3")).to eq 3.days
      end
    end
  end

  describe ".format" do
    context "with singular values" do
      it do
        expect(SS::Duration.format(1.year)).to eq I18n.t("datetime.distance_in_words.x_years", count: 1)
        expect(SS::Duration.format(1.month)).to eq I18n.t("datetime.distance_in_words.x_months", count: 1)
        expect(SS::Duration.format(1.week)).to eq I18n.t("datetime.distance_in_words.x_weeks", count: 1)
        expect(SS::Duration.format(1.day)).to eq I18n.t("datetime.distance_in_words.x_days", count: 1)
        expect(SS::Duration.format(1.hour)).to eq I18n.t("datetime.distance_in_words.x_hours", count: 1)
        expect(SS::Duration.format(1.minute)).to eq I18n.t("datetime.distance_in_words.x_minutes", count: 1)
        expect(SS::Duration.format(1.second)).to eq I18n.t("datetime.distance_in_words.x_seconds", count: 1)
      end
    end

    context "with composite / complex duration" do
      let(:years) { rand(2..5) }
      let(:months) { rand(2..5) }
      let(:weeks) { rand(2..5) }
      let(:days) { rand(2..5) }
      let(:hours) { rand(2..5) }
      let(:minutes) { rand(2..5) }
      let(:seconds) { rand(2..5) }
      subject { years.years + months.months + weeks.weeks + days.days + hours.hours + minutes.minutes + seconds.seconds }

      it do
        expect(SS::Duration.format(subject)).to include I18n.t("datetime.distance_in_words.x_years", count: years)
        expect(SS::Duration.format(subject)).to include I18n.t("datetime.distance_in_words.x_months", count: months)
        expect(SS::Duration.format(subject)).to include I18n.t("datetime.distance_in_words.x_weeks", count: weeks)
        expect(SS::Duration.format(subject)).to include I18n.t("datetime.distance_in_words.x_days", count: days)
        expect(SS::Duration.format(subject)).to include I18n.t("datetime.distance_in_words.x_hours", count: hours)
        expect(SS::Duration.format(subject)).to include I18n.t("datetime.distance_in_words.x_minutes", count: minutes)
        expect(SS::Duration.format(subject)).to include I18n.t("datetime.distance_in_words.x_seconds", count: seconds)
      end
    end
  end
end
