module Event::Addon
  module IcalImport
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ical_import_url, type: String
      field :ical_max_docs, type: Integer
      field :ical_refresh_method, type: String
      field :ical_page_state, type: String
      field :ical_import_date_ago, type: Integer
      field :ical_import_date_after, type: Integer
      permit_params :ical_import_url, :ical_max_docs, :ical_refresh_method, :ical_page_state
      permit_params :ical_import_date_ago, :ical_import_date_after
      validates :ical_page_state, inclusion: { in: %w(public closed), allow_blank: true }
    end

    def ical_refresh_method_options
      %w(manual auto).map { |m| [ I18n.t("event.options.ical_refresh_method.#{m}"), m ] }.to_a
    end

    def ical_page_state_options
      %w(public closed).map { |value| [I18n.t("ss.options.state.#{value}"), value] }
    end
  end
end
