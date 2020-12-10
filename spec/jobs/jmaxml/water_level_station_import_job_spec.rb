require 'spec_helper'

describe Jmaxml::WaterLevelStationImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:file) { "#{Rails.root}/spec/fixtures/jmaxml/water_level_stations.zip" }

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

    expect(Jmaxml::WaterLevelStation.count).to eq 7

    # 81010100010000004
    Jmaxml::WaterLevelStation.find_by(code: '81010100010000004').tap do |region|
      expect(region.name).to eq '天塩大橋'
      expect(region.region_name).to eq '天塩川'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 81010100010000011
    Jmaxml::WaterLevelStation.find_by(code: '81010100010000011').tap do |region|
      expect(region.name).to eq '誉平'
      expect(region.region_name).to eq '天塩川'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 81010100010000008
    Jmaxml::WaterLevelStation.find_by(code: '81010100010000008').tap do |region|
      expect(region.name).to eq '美深橋'
      expect(region.region_name).to eq '天塩川'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 81010100010000007
    Jmaxml::WaterLevelStation.find_by(code: '81010100010000007').tap do |region|
      expect(region.name).to eq '名寄大橋'
      expect(region.region_name).to eq '天塩川'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 81010100010000005
    Jmaxml::WaterLevelStation.find_by(code: '81010100010000005').tap do |region|
      expect(region.name).to eq '九十九橋'
      expect(region.region_name).to eq '天塩川'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 01017500010000013
    Jmaxml::WaterLevelStation.find_by(code: '01017500010000013').tap do |region|
      expect(region.name).to eq '天狗橋'
      expect(region.region_name).to eq '札幌市新川水系　新川'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 02003600010000018
    Jmaxml::WaterLevelStation.find_by(code: '02003600010000018').tap do |region|
      expect(region.name).to eq '新妙見橋'
      expect(region.region_name).to eq '青森県堤川水系　堤川・駒込川'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end
  end
end
