require 'spec_helper'

describe Gws::Affair2::Loader::Common::Cup, type: :model, dbscope: :example do
  it do
    item = described_class.new(100)
    v1 = item.pour(30)
    expect(v1).to eq 0
    expect(item.value).to eq 30

    v2 = item.pour(20)
    expect(v2).to eq 0
    expect(item.value).to eq 50

    v3 = item.pour(60)
    expect(v3).to eq 10
    expect(item.value).to eq 100

    v4 = item.pour(50)
    expect(v4).to eq 50
    expect(item.value).to eq 100
  end

  it do
    item = described_class.new(0)
    v1 = item.pour(50)
    expect(v1).to eq 50
    expect(item.value).to eq 0

    v2 = item.pour(50)
    expect(v2).to eq 50
    expect(item.value).to eq 0
  end
end
