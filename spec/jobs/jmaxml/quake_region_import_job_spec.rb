require 'spec_helper'

describe Jmaxml::QuakeRegionImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:file) { "#{Rails.root}/spec/fixtures/jmaxml/quake_regions.zip" }

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

    expect(Jmaxml::QuakeRegion.count).to eq 5

    # 100
    Jmaxml::QuakeRegion.find_by(code: '100').tap do |region|
      expect(region.name).to eq '石狩地方北部'
      expect(region.yomi).to eq 'いしかりちほうほくぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 101
    Jmaxml::QuakeRegion.find_by(code: '101').tap do |region|
      expect(region.name).to eq '石狩地方中部'
      expect(region.yomi).to eq 'いしかりちほうちゅうぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 102
    Jmaxml::QuakeRegion.find_by(code: '102').tap do |region|
      expect(region.name).to eq '石狩地方南部'
      expect(region.yomi).to eq 'いしかりちほうなんぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 105
    Jmaxml::QuakeRegion.find_by(code: '105').tap do |region|
      expect(region.name).to eq '渡島地方北部'
      expect(region.yomi).to eq 'おしまちほうほくぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end

    # 106
    Jmaxml::QuakeRegion.find_by(code: '106').tap do |region|
      expect(region.name).to eq '渡島地方東部'
      expect(region.yomi).to eq 'おしまちほうとうぶ'
      expect(region.order).to eq 0
      expect(region.state).to eq 'enabled'
    end
  end
end
