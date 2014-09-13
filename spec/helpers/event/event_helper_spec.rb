require 'spec_helper'
require 'timecop'

include Event::EventHelper

def date_when(date_opts = {})
  return Date.current if date_opts.empty?
  Date.current.change(date_opts)
end

describe Event::EventHelper do

  before { Timecop.freeze(date_when(year: 2014, month: 9, day: 14)) }

  subject { Event::EventHelper }

  context '#within_one_year?' do
    it 'given current date returns true'

    # start_date
    it 'given 2013/12/31 returns true'
    it 'given 2012/12/30 returns false'

    # close_date
    it 'given 2015/09/01 returns true'
    it 'given 2015/09/02 returns false'

  end

  after { Timecop.return }
end
