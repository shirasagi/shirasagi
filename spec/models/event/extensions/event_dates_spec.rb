require 'spec_helper'

describe Event::Extensions::EventDates, type: :model, dbscope: :example do
  describe ".demongoize" do
    context "when nil is given" do
      subject { described_class.demongoize(nil) }

      it do
        expect(subject).to be_nil
      end
    end

    context "when empty array is given" do
      subject { described_class.demongoize([]) }

      it do
        expect(subject).to be_a(described_class)
        expect(subject).to have(0).items
      end
    end

    context "when expected date array is given" do
      subject { described_class.demongoize([ Date.parse("2021/09/16") ]) }

      it do
        expect(subject).to be_a(described_class)
        expect(subject).to have(1).items
        expect(subject[0]).to eq "2021/09/16".in_time_zone.to_date
      end
    end
  end

  describe ".mongoize" do
    context "when nil is given" do
      subject { described_class.mongoize(nil) }

      it do
        expect(subject).to be_nil
      end
    end

    # string-form is convenient for editing with textarea on a browser
    context "when string is given" do
      context "when empty string is given" do
        subject { described_class.mongoize("") }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to be_empty
        end
      end

      context "when a date string is given" do
        subject { described_class.mongoize("2021/09/15") }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(1).item
          expect(subject.first).to be_a(Date)
          expect(subject.first).to eq Time.find_zone("UTC").parse("2021/09/15")
        end
      end

      context "when a non-date string is given" do
        subject { described_class.mongoize("hello") }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to be_empty
        end
      end

      context "when multiline date string (LF) is given" do
        subject { described_class.mongoize("2021/09/15\n2021/09/16\n2021/09/17\n2021/09/20") }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(4).item
          expect(subject[0]).to eq Time.find_zone("UTC").parse("2021/09/15")
          expect(subject[1]).to eq Time.find_zone("UTC").parse("2021/09/16")
          expect(subject[2]).to eq Time.find_zone("UTC").parse("2021/09/17")
          expect(subject[3]).to eq Time.find_zone("UTC").parse("2021/09/20")
        end
      end

      context "when multiline date string (CRLF) is given" do
        subject { described_class.mongoize("2021/09/15\r\n2021/09/16\r\n2021/09/17\r\n2021/09/20") }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(4).item
          expect(subject[0]).to eq Time.find_zone("UTC").parse("2021/09/15")
          expect(subject[1]).to eq Time.find_zone("UTC").parse("2021/09/16")
          expect(subject[2]).to eq Time.find_zone("UTC").parse("2021/09/17")
          expect(subject[3]).to eq Time.find_zone("UTC").parse("2021/09/20")
        end
      end
    end

    # array-form is convenient for writing specs
    context "when array is given" do
      context "when empty array is given" do
        subject { described_class.mongoize([]) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to be_empty
        end
      end

      context "when array which contains nil is given" do
        subject { described_class.mongoize([ nil ]) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to be_empty
        end
      end

      context "when a local Time is given" do
        let(:now) { Time.zone.now }
        subject { described_class.mongoize([ now ]) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(1).item
          expect(subject.first).to be_a(Date)
          expect(subject.first.in_time_zone).to eq now.beginning_of_day
        end
      end

      context "when a local Date is given" do
        let(:today) { Time.zone.now.to_date }
        subject { described_class.mongoize([ today ]) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(1).item
          expect(subject.first).to be_a(Date)
          expect(subject.first).to eq today
        end
      end

      context "when not-Date string is given" do
        subject { described_class.mongoize(%w(hello)) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to be_empty
        end
      end
    end
  end

  describe "#clustered" do
    context "when empty array is given" do
      let(:item) { described_class.demongoize([]) }
      subject { item.clustered }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(0).items
      end
    end

    context "when single date is given" do
      let(:item) { described_class.demongoize([ "2021/09/16" ]) }
      subject { item.clustered }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(Array)
        expect(subject[0]).to have(1).items
        expect(subject[0]).to eq [ "2021/09/16".in_time_zone.to_date ]
      end
    end

    context "when 2 consecutive dates are given" do
      let(:item) { described_class.demongoize(%w(2021/09/16 2021/09/17)) }
      subject { item.clustered }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(Array)
        expect(subject[0]).to have(2).items
        expect(subject[0]).to eq [ "2021/09/16".in_time_zone.to_date, "2021/09/17".in_time_zone.to_date ]
      end
    end

    context "when 2 consecutive dates and single date are given" do
      let(:item) { described_class.demongoize(%w(2021/09/16 2021/09/17 2021/10/16)) }
      subject { item.clustered }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(2).items
        expect(subject[0]).to be_a(Array)
        expect(subject[0]).to have(2).items
        expect(subject[0]).to eq [ "2021/09/16".in_time_zone.to_date, "2021/09/17".in_time_zone.to_date ]
        expect(subject[1]).to be_a(Array)
        expect(subject[1]).to have(1).items
        expect(subject[1]).to eq [ "2021/10/16".in_time_zone.to_date ]
      end
    end
  end
end
