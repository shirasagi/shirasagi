module Gws::Workload::Sort
  extend ActiveSupport::Concern

  def sort_options
    %w(due_date_desc due_date_asc updated_desc updated_asc created_desc created_asc).map do |k|
      [I18n.t("gws/workload.options.sort.#{k}"), k]
    end
  end
end
