module MailPage::Addon
  module ArrivalPlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :arrival_start_date, type: DateTime
      field :arrival_close_date, type: DateTime

      validates :arrival_start_date, datetime: true
      validates :arrival_close_date, datetime: true
      validate :validate_arrival_date

      permit_params :arrival_start_date, :arrival_close_date

      scope :and_arrival, ->(date = nil) {
        date = Time.zone.now if date.nil?
        where("$and" => [
          { "$or" => [{ arrival_start_date: nil }, { :arrival_start_date.lte => date }] },
          { "$or" => [{ arrival_close_date: nil }, { :arrival_close_date.gt => date }] },
        ])
      }
    end

    private

    def validate_arrival_date
      if arrival_close_date.present? && arrival_start_date.present? && arrival_start_date >= arrival_close_date
        errors.add :arrival_close_date, :greater_than, count: t(:arrival_start_date)
      end
    end
  end
end
