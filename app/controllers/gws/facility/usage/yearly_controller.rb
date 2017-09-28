class Gws::Facility::Usage::YearlyController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Facility::UsageFilter

  private

  def target_range
    1.year
  end

  def aggregation_ids
    {
      'facility_id' => '$facility_ids',
      'year' => { '$year' => '$local_start_at' },
      'month' => { '$month' => '$local_start_at' }
    }
  end
end
