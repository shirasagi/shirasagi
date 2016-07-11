require 'spec_helper'

describe Map::Extensions::Loc, dbscope: :example do
  describe '#initialize' do
    it do
      loc = described_class[ 34.0676396, 134.5891117 ]
      expect(loc.lat).to eq 34.0676396
      expect(loc.lng).to eq 134.5891117
    end
  end

  describe '#mongoize' do
    it do
      loc = described_class[ 34.0676396, 134.5891117 ].mongoize
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end
  end

  describe '#empty?' do
    it do
      loc = described_class[ 34.0676396, 134.5891117 ]
      expect(loc.empty?).to be_falsey
      expect(loc.blank?).to be_falsey
      expect(loc.present?).to be_truthy
    end

    it do
      loc = described_class.new
      expect(loc.empty?).to be_truthy
      expect(loc.blank?).to be_truthy
      expect(loc.present?).to be_falsey
    end
  end

  describe ".demongoize" do
    it do
      loc = described_class.demongoize([ 34.0676396, 134.5891117 ])
      expect(loc).to be_a(described_class)
      expect(loc.lat).to eq 34.0676396
      expect(loc.lng).to eq 134.5891117
    end

    it do
      loc = described_class.demongoize([])
      expect(loc).to be_a(described_class)
      expect(loc.lat).to be_nil
      expect(loc.lng).to be_nil
    end

    it do
      loc = described_class.demongoize(nil)
      expect(loc).to be_a(described_class)
      expect(loc.lat).to be_nil
      expect(loc.lng).to be_nil
    end
  end

  describe ".mongoize" do
    it do
      loc = described_class.mongoize(described_class[34.0676396, 134.5891117])
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize([ 34.0676396, 134.5891117 ])
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize([ '34.0676396', '134.5891117' ])
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize({lat: 34.0676396, lng: 134.5891117})
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize({lat: '34.0676396', lng: '134.5891117'})
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize({'lat' => 34.0676396, 'lng' => 134.5891117})
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize({'lat' => '34.0676396', 'lng' => '134.5891117'})
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize("34.0676396 134.5891117")
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end

    it do
      loc = described_class.mongoize('')
      expect(loc).to be_a(Array)
      expect(loc).to eq []
    end

    it do
      loc = described_class.mongoize('abc xyz')
      expect(loc).to be_a(Array)
      expect(loc).to eq []
    end

    it do
      loc = described_class.mongoize(nil)
      expect(loc).to be_nil
    end

    it do
      loc = described_class.mongoize(%w(xyz abc))
      expect(loc).to be_a(Array)
      expect(loc).to eq []
    end
  end

  describe '.evolve' do
    it do
      loc = described_class.evolve(described_class[34.0676396, 134.5891117])
      expect(loc).to be_a(Array)
      expect(loc).to eq [ 34.0676396, 134.5891117 ]
    end
  end
end
