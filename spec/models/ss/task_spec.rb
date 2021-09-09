require 'spec_helper'

describe SS::Task, dbscope: :example do
  describe "#running?" do
    let(:now) { Time.zone.now.beginning_of_minute }
    subject! { described_class.create!(name: unique_id, state: "running", started: now) }

    it do
      Timecop.freeze(now) do
        expect(subject.running?).to be_truthy
      end

      Timecop.freeze(now + SS::Task::RUN_EXPIRATION - 1.second) do
        expect(subject.running?).to be_truthy
      end

      Timecop.freeze(now + SS::Task::RUN_EXPIRATION) do
        expect(subject.running?).to be_falsey
      end
    end
  end
end
