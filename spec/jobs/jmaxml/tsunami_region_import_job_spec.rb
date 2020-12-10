require 'spec_helper'

describe Jmaxml::TsunamiRegionImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:file) { "#{Rails.root}/spec/fixtures/jmaxml/tsunami_regions.zip" }

  before do
    described_class.import_from_zip(file, site_id: site)
  end

  it do
    expect(Job::Log.count).to eq 1
    Job::Log.first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    expect(SS::TempFile.count).to eq 0

    expect(Jmaxml::TsunamiRegion.count).to eq 5

    # 100
    Jmaxml::TsunamiRegion.find_by(code: '100').tap do |region|
      expect(region.name).to eq '北海道太平洋沿岸東部'
      expect(region.yomi).to eq 'ほっかいどうたいへいようえんがんとうぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 101
    Jmaxml::TsunamiRegion.find_by(code: '101').tap do |region|
      expect(region.name).to eq '北海道太平洋沿岸中部'
      expect(region.yomi).to eq 'ほっかいどうたいへいようえんがんちゅうぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 102
    Jmaxml::TsunamiRegion.find_by(code: '102').tap do |region|
      expect(region.name).to eq '北海道太平洋沿岸西部'
      expect(region.yomi).to eq 'ほっかいどうたいへいようえんがんせいぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 110
    Jmaxml::TsunamiRegion.find_by(code: '110').tap do |region|
      expect(region.name).to eq '北海道日本海沿岸北部'
      expect(region.yomi).to eq 'ほっかいどうにほんかいえんがんほくぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 111
    Jmaxml::TsunamiRegion.find_by(code: '111').tap do |region|
      expect(region.name).to eq '北海道日本海沿岸南部'
      expect(region.yomi).to eq 'ほっかいどうにほんかいえんがんなんぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end
  end
end
