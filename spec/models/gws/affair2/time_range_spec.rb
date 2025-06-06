require 'spec_helper'

describe Gws::Affair2::Utils, type: :model, dbscope: :example do
  let(:main_range) do
    start = Time.zone.parse("2025/1/14 8:30")
    close = Time.zone.parse("2025/1/14 17:15")
    (start..close)
  end
  let(:sub_range1) do
    start = Time.zone.parse("2025/1/14 8:30")
    close = Time.zone.parse("2025/1/14 10:30")
    (start..close)
  end

  it do
    minutes = described_class.time_range_minutes(main_range, sub_range1)
    expect(minutes.size).to eq 2
    expect(minutes[0]).to eq 405
    expect(minutes[1]).to eq 120
  end
end
