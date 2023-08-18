require 'spec_helper'

describe Jmaxml::ForecastRegionImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:file) { "#{Rails.root}/spec/fixtures/jmaxml/forecast_regions.zip" }

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

    expect(Jmaxml::ForecastRegion.count).to eq 5

    # 0110000
    Jmaxml::ForecastRegion.find_by(code: '0110000').tap do |region|
      expect(region.name).to eq '北海道札幌市'
      expect(region.yomi).to eq 'ほっかいどうさっぽろし'
      expect(region.short_name).to eq '札幌市'
      expect(region.short_yomi).to eq 'さっぽろし'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 0120200
    Jmaxml::ForecastRegion.find_by(code: '0120200').tap do |region|
      expect(region.name).to eq '北海道函館市'
      expect(region.yomi).to eq 'ほっかいどうはこだてし'
      expect(region.short_name).to eq '函館市'
      expect(region.short_yomi).to eq 'はこだてし'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 0120300
    Jmaxml::ForecastRegion.find_by(code: '0120300').tap do |region|
      expect(region.name).to eq '北海道小樽市'
      expect(region.yomi).to eq 'ほっかいどうおたるし'
      expect(region.short_name).to eq '小樽市'
      expect(region.short_yomi).to eq 'おたるし'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 0120400
    Jmaxml::ForecastRegion.find_by(code: '0120400').tap do |region|
      expect(region.name).to eq '北海道旭川市'
      expect(region.yomi).to eq 'ほっかいどうあさひかわし'
      expect(region.short_name).to eq '旭川市'
      expect(region.short_yomi).to eq 'あさひかわし'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 0120500
    Jmaxml::ForecastRegion.find_by(code: '0120500').tap do |region|
      expect(region.name).to eq '北海道室蘭市'
      expect(region.yomi).to eq 'ほっかいどうむろらんし'
      expect(region.short_name).to eq '室蘭市'
      expect(region.short_yomi).to eq 'むろらんし'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end
  end
end
