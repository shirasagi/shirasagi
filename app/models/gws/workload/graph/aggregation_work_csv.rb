module Gws::Workload::Graph::AggregationWorkCsv
  extend ActiveSupport::Concern

  def aggregate_work_enum_csv
    pipes = []
    pipes << { "$match" => items.selector }
    pipes << { "$unwind" => "$year_months" }
    pipes << { "$match" => { "year_months.year" => year } }
    pipes << { "$sort" => { "due_start_on" => 1 } }

    work_by_months = Gws::Workload::Work.collection.aggregate(pipes)
    work_by_months = work_by_months.to_a

    work_csv(work_by_months)
  end

  private

  def work_csv_headers
    %w(
      year month
      name
      due_date due_start_on due_end_on
      category_id client_id cycle_id load_id
      member_ids member_group_id
    ).map { |key| Gws::Workload::Work.t(key) }
  end

  def dig_date(data, key)
    data[key.to_s].in_time_zone.strftime('%Y/%m/%d')
  rescue
    nil
  end

  def dig_category_name(data, key)
    @category_h ||= categories.index_by(&:id)
    @category_h[data[key.to_s]].name
  rescue
    nil
  end

  def dig_client_name(data, key)
    @client_h ||= clients.index_by(&:id)
    @client_h[data[key.to_s]].name
  rescue
    nil
  end

  def dig_cycle_name(data, key)
    @cycle_h ||= cycles.index_by(&:id)
    @cycle_h[data[key.to_s]].name
  rescue
    nil
  end

  def dig_load_name(data, key)
    @load_h ||= loads.index_by(&:id)
    @load_h[data[key.to_s]].name
  rescue
    nil
  end

  def dig_member_names(data, key)
    @user_h ||= Gws::User.unscoped.to_a.index_by(&:id)
    data[key.to_s].to_a.filter_map { |id| @user_h[id].try(:name) }
  end

  def dig_member_group_name(data, key)
    @group_h ||= Gws::Group.unscoped.to_a.index_by(&:id)
    @group_h[data[key.to_s]].name
  rescue
    nil
  end

  def work_csv(work_by_months)
    Enumerator.new do |y|
      y << encode_sjis(work_csv_headers.to_csv)
      work_by_months.each do |data|
        row = []
        row << data["year"]
        row << data["year_months"]["month"]
        row << data["name"]
        row << dig_date(data, :due_date)
        row << dig_date(data, :due_start_on)
        row << dig_date(data, :due_end_on)
        row << dig_category_name(data, :category_id)
        row << dig_client_name(data, :client_id)
        row << dig_cycle_name(data, :cycle_id)
        row << dig_load_name(data, :load_id)
        row << dig_member_names(data, :member_ids).join("\n")
        row << dig_member_group_name(data, :member_group_id)
        y << encode_sjis(row.to_csv)
      end
    end
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
