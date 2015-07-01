module Cms::Addon
  module Tabs
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :conditions, type: SS::Extensions::Words
      field :limit, type: Integer, default: 8
      field :new_days, type: Integer, default: 1
      permit_params :conditions, :limit, :new_days

      before_validation :validate_conditions
    end

    public
      def limit
        value = self[:limit].to_i
        (value < 1 || 1000 < value) ? 100 : value
      end

      def new_days
        value = self[:new_days].to_i
        (value < 0 || 30 < value) ? 30 : value
      end

      def in_new_days?(date)
        date + new_days > Time.zone.now
      end

    private
      def validate_conditions
        self.conditions = conditions.map do |m|
          m.strip.sub(/^\w+:\/\/.*?\//, "").sub(/^\//, "").sub(/\/$/, "")
        end.compact.uniq
      end
  end
end
