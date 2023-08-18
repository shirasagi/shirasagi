module Gws::Affair::Aggregator
  class Capital
    def initialize(criteria)
      @partition = Partition.new(criteria)
    end

    def capital_aggregate_by_month
      @prefs = {}
      @aggregation = @partition.aggregate_partition
      @aggregation.each do |user_id, files|
        files.each do |file_id, i|
          fiscal_year = i[:fiscal_year]
          month = i[:month]
          capital_code = i[:capital_code]
          overtime_minute = i[:overtime_minute]

          @prefs[fiscal_year] ||= {}
          @prefs[fiscal_year][month] ||= {}
          @prefs[fiscal_year][month][capital_code] ||= 0
          @prefs[fiscal_year][month][capital_code] += overtime_minute

          @prefs[fiscal_year][month]["total"] ||= 0
          @prefs[fiscal_year][month]["total"] += overtime_minute
        end
      end
      [@prefs, @aggregation]
    end

    def capital_aggregate_by_group
      @prefs = {}
      @aggregation = @partition.aggregate_partition
      @aggregation.each do |user_id, files|
        files.each do |file_id, i|
          capital_code = i[:capital_code]
          group_id = i[:group_id]
          overtime_minute = i[:overtime_minute]

          @prefs[group_id] ||= {}
          @prefs[group_id][capital_code] ||= 0
          @prefs[group_id][capital_code] += overtime_minute

          @prefs[group_id]["total"] ||= 0
          @prefs[group_id]["total"] += overtime_minute
        end
      end
      [@prefs, @aggregation]
    end

    def capital_aggregate_by_group_users
      @prefs = {}
      @aggregation = @partition.aggregate_partition
      @aggregation.each do |user_id, files|
        files.each do |file_id, i|
          capital_code = i[:capital_code]
          group_id = i[:group_id]
          overtime_minute = i[:overtime_minute]

          @prefs[user_id] ||= {}
          @prefs[user_id][group_id] ||= {}
          @prefs[user_id][group_id][capital_code] ||= 0
          @prefs[user_id][group_id][capital_code] += overtime_minute

          @prefs[user_id][group_id]["total"] ||= 0
          @prefs[user_id][group_id]["total"] += overtime_minute
        end
      end
      [@prefs, @aggregation]
    end

    def capital_aggregate_by_users
      @prefs = {}
      @aggregation = @partition.aggregate_partition
      @aggregation.each do |user_id, files|
        files.each do |file_id, i|
          capital_code = i[:capital_code]
          overtime_minute = i[:overtime_minute]

          @prefs[user_id] ||= {}
          @prefs[user_id][capital_code] ||= 0
          @prefs[user_id][capital_code] += overtime_minute

          @prefs[user_id]["total"] ||= 0
          @prefs[user_id]["total"] += overtime_minute
        end
      end
      [@prefs, @aggregation]
    end
  end
end
