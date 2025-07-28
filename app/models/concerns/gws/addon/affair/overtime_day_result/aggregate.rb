module Gws::Addon::Affair::OvertimeDayResult
  module Aggregate
    extend ActiveSupport::Concern

    module ClassMethods
      # base
      def aggregate_partition(opts = {})
        criteria = self.criteria
        aggregator = Gws::Affair::Aggregator::Partition.new(criteria)
        aggregator.aggregate_partition(opts)
      end

      # capital
      def capital_aggregate_by_month
        criteria = self.criteria
        aggregator = Gws::Affair::Aggregator::Capital.new(criteria)
        aggregator.capital_aggregate_by_month
      end

      def capital_aggregate_by_group
        criteria = self.criteria
        aggregator = Gws::Affair::Aggregator::Capital.new(criteria)
        aggregator.capital_aggregate_by_group
      end

      def capital_aggregate_by_group_users
        criteria = self.criteria
        aggregator = Gws::Affair::Aggregator::Capital.new(criteria)
        aggregator.capital_aggregate_by_group_users
      end

      def capital_aggregate_by_users
        criteria = self.criteria
        aggregator = Gws::Affair::Aggregator::Capital.new(criteria)
        aggregator.capital_aggregate_by_users
      end

      # user
      def user_aggregate
        criteria = self.criteria
        aggregator = Gws::Affair::Aggregator::User.new(criteria)
        aggregator.user_aggregate
      end
    end
  end
end
