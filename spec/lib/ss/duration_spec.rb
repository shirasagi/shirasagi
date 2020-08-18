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
end
