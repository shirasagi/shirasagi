module Inquiry::Addon
  module ReceptionPlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reception_start_date, type: DateTime
      field :reception_close_date, type: DateTime
      permit_params :reception_start_date, :reception_close_date

      validate :validate_reception_date
    end

    def reception_enabled?
      if (reception_start_date.present? && reception_start_date.to_date > Time.zone.now.to_date) ||
         (reception_close_date.present? && reception_close_date.to_date < Time.zone.now.to_date)
        false
      else
        true
      end
    end

    private
      def validate_reception_date
        if reception_start_date.present? || reception_close_date.present?
          if reception_start_date.blank?
            errors.add :reception_start_date, :empty
          elsif reception_close_date.blank?
            errors.add :reception_close_date, :empty
          elsif reception_start_date > reception_close_date
            errors.add :reception_close_date, :greater_than, count: t(:reception_start_date)
          end
        end
      end
  end
end
