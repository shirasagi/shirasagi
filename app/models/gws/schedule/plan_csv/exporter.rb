class Gws::Schedule::PlanCsv::Exporter
  include ActiveModel::Model

  attr_accessor :site, :user
  attr_accessor :criteria

  class << self
    def csv_basic_headers
      headers = %w(
        id state name start_on end_on start_at end_at allday
        category_id priority color text_type text
        attendance_check_state
        member_ids member_custom_group_ids
        facility_ids main_facility_id facility_column_values
        readable_setting_range readable_member_ids readable_group_ids readable_custom_group_ids
        custom_group_ids group_ids user_ids permission_level
      )
      #repeat_plan_id, file_ids
      headers.map! { |k| Gws::Schedule::Plan.t(k) }
    end

    def csv_headers(opts = {})
      new(opts).csv_headers
    end

    def enum_csv(criteria, opts = {})
      opts = opts.dup
      opts[:criteria] = criteria
      new(opts).enum_csv
    end

    def to_csv(criteria, opts = {})
      enum_csv(criteria, opts).to_a.to_csv
    end
  end

  def csv_headers
    self.class.csv_basic_headers
  end

  def enum_csv
    Enumerator.new do |y|
      y << encode_sjis(csv_headers.to_csv)
      @criteria.each do |item|
        next unless item.readable?(user) || item.member?(user)
        y << encode_sjis(item_to_csv(item).to_csv)
      end
    end
  end

  private

  def item_to_csv(item)
    terms = []
    terms << item.id
    terms << item.state
    terms << item.name
    terms << item.start_on
    terms << item.end_on
    terms << item.start_at
    terms << item.end_at
    terms << item.allday
    terms << item.category_id
    terms << item.priority
    terms << item.color
    terms << item.text_type
    terms << item.text
    terms << item.attendance_check_state
    terms << item.member_ids.to_json
    terms << item.member_custom_group_ids.to_json
    terms << item.facility_ids.to_json
    terms << item.main_facility_id
    terms << item.facility_column_values.to_json
    terms << item.readable_setting_range
    terms << item.readable_member_ids.to_json
    terms << item.readable_group_ids.to_json
    terms << item.readable_custom_group_ids.to_json
    terms << item.custom_group_ids.to_json
    terms << item.group_ids.to_json
    terms << item.user_ids.to_json
    terms << item.permission_level
    terms
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
