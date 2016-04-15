module Inquiry::Addon
  module ReleasePlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :release_date, type: DateTime
      field :close_date, type: DateTime
      permit_params :release_date, :close_date

      validates :release_date, datetime: true
      validates :close_date, datetime: true
      validate :validate_release_date

      scope :and_public, ->(date = nil) {
        date ||= Time.zone.now
        where("$and" => [
          { "$or" => [ { state: "public", :released.lte => date }, { :release_date.lte => date } ] },
          { "$or" => [ { close_date: nil }, { :close_date.gt => date } ] },
        ])
      }
    end

    def public?
      if (release_date.present? && release_date > Time.zone.now) ||
         (close_date.present? && close_date < Time.zone.now)
        false
      else
        super
      end
    end

    def label(name)
      if name == :state
        state = public? ? "public" : "closed"
        I18n.t("views.options.state.#{state}")
      else
        super(name)
      end
    end

    private
      def validate_release_date
        self.released ||= release_date

        if close_date.present?
          if release_date.present? && release_date >= close_date
            errors.add :close_date, :greater_than, count: t(:release_date)
          end
        end
      end
  end
end
