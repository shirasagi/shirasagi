class Gws::StaffRecord::YearlyGroupComponent < ApplicationComponent
  include SS::CacheableComponent

  self.cache_key = ->{ [ cur_site.id, cur_year.id, max_updated.to_i ] }

  def initialize(cur_site:, cur_year:, selected:)
    super()
    @cur_site = cur_site
    @cur_year = cur_year
    @selected = selected
  end

  attr_reader :cur_site, :cur_year, :selected

  def section_options
    @section_options ||= cur_year.yearly_groups.map do |c|
      [ c.name, c.name, { data: { id: c.id } } ]
    end
  end

  def max_updated
    @max_updated ||= cur_year.yearly_groups.max(:updated)
  end
end
