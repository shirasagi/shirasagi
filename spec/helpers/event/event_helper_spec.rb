require 'spec_helper'
require 'timecop'

describe Event::EventHelper, type: :helper do

  def date_when(year:, month:, day:)
    Time.zone.today.change(year: year, month: month, day: day)
  end

  before { Timecop.freeze(date_when(year: 2014, month: 9, day: 14)) }

  context '#within_one_year?' do
    it 'given current date returns true' do
      date = Time.zone.today # 2014/09/14
      expect(helper.within_one_year?(date)).to eq true
    end

    # start_date
    it 'given 2013/12/31 returns true' do
      date = date_when(year: 2013, month: 12, day: 31)
      expect(helper.within_one_year?(date)).to eq true
    end

    it 'given 2012/12/30 returns false' do
      date = date_when(year: 2012, month: 12, day: 30)
      expect(helper.within_one_year?(date)).to eq false
    end

    # close_date
    it 'given 2015/09/01 returns true' do
      date = date_when(year: 2015, month: 9, day: 1)
      expect(helper.within_one_year?(date)).to eq true
    end

    it 'given 2015/09/02 returns false' do
      date = date_when(year: 2015, month: 10, day: 2)
      expect(helper.within_one_year?(date)).to eq false
    end
  end

  after { Timecop.return }
end
