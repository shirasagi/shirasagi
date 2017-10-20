module Gws::Addon::Schedule::Reports
  extend ActiveSupport::Concern
  extend SS::Addon

  def reports
    Gws::Report::File.site(@cur_site || self.site).schedule(self)
  end
end
