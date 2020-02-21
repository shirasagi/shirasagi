module Gws::Circular::Sort
  extend ActiveSupport::Concern

  def sort_options
    %w(due_date_desc due_date_asc updated_desc updated_asc created_desc created_asc).map do |k|
      [I18n.t("gws/circular.options.sort.#{k}"), k]
    end
  end
end
