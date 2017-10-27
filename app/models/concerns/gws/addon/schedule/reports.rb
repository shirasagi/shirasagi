module Gws::Addon::Schedule::Reports
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_report_ids, :in_initial_report_ids
    permit_params in_report_ids: [], in_initial_report_ids: []

    after_save :save_related_reports
  end

  def reports
    Gws::Report::File.site(@cur_site || self.site).schedule(self)
  end

  private

  def save_related_reports
    report_ids = Array(in_report_ids)
    initial_report_ids = Array(in_initial_report_ids)

    # add relation
    Gws::Report::File.in(id: report_ids - initial_report_ids).add_to_set(schedule_ids: self.id.to_s)

    # remove relation
    Gws::Report::File.in(id: initial_report_ids - report_ids).pull(schedule_ids: self.id.to_s)
  end
end
