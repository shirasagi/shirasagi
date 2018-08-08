module Event::Addon
  module IcalImport
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ical_import_url, type: String
      field :ical_basic_user, type: String
      field :ical_basic_password, type: String
      field :ical_max_docs, type: Integer
      field :ical_refresh_method, type: String
      field :ical_page_state, type: String
      field :ical_import_date_ago, type: Integer
      field :ical_import_date_after, type: Integer
      permit_params :ical_import_url, :ical_basic_user, :ical_basic_password, :ical_max_docs
      permit_params :ical_refresh_method, :ical_page_state, :ical_import_date_ago, :ical_import_date_after
      validates :ical_refresh_method, inclusion: { in: %w(manual auto), allow_blank: true }
      validates :ical_page_state, inclusion: { in: %w(public closed), allow_blank: true }
      validates :ical_import_date_ago, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
      validates :ical_import_date_after, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
    end

    def ical_refresh_method_options
      %w(manual auto).map { |m| [ I18n.t("event.options.ical_refresh_method.#{m}"), m ] }.to_a
    end

    def ical_page_state_options
      %w(public closed).map { |value| [I18n.t("ss.options.state.#{value}"), value] }
    end

    def ical_url_options
      opts = {}
      if ical_basic_user.present? && ical_basic_password.present?
        opts[:http_basic_authentication] = [ical_basic_user, ical_basic_password]
      end
      opts
    end

    def ical_parse
      uri = URI.parse(ical_import_url)
      file = open(uri, ical_url_options)
      Icalendar::Calendar.parse(file.read)
    end
  end
end
