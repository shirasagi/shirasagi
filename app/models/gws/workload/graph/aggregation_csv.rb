module Gws::Workload::Graph::AggregationCsv
  extend ActiveSupport::Concern

  def aggregate_work_enum_csv
    category_h = categories.index_by(&:id)
    load_h = loads.index_by(&:id)
    client_h = clients.index_by(&:id)
    cycle_h = cycles.index_by(&:id)

    user_h = Gws::User.all.to_a.index_by(&:id)
    group_h = Gws::Group.all.to_a.index_by(&:id)

    pipes = []
    pipes << { "$match" => items.selector }
    pipes << { "$unwind" => "$year_months" }
    pipes << { "$match" => { "year_months.year" => year } }
    pipes << { "$sort" => { "due_start_on" => 1 } }

    aggregation = Gws::Workload::Work.collection.aggregate(pipes)
    aggregation = aggregation.to_a

    Enumerator.new do |y|
      headers = %w(
        year month
        name
        due_date due_start_on due_end_on
        category_id client_id cycle_id load_id
        member_ids member_group_id).map { |key| Gws::Workload::Work.t(key) }
      y << encode_sjis(headers.to_csv)

      aggregation.each do |data|
        due_date = data["due_date"].strftime('%Y/%m/%d') rescue nil
        due_start_on = data["due_start_on"].strftime('%Y/%m/%d') rescue nil
        due_end_on = data["due_end_on"].strftime('%Y/%m/%d') rescue nil

        category_name = category_h[data["category_id"]].name rescue nil
        client_name = client_h[data["client_id"]].name rescue nil
        cycle_name = cycle_h[data["cycle_id"]].name rescue nil
        load_name = load_h[data["load_id"]].name rescue nil

        member_names = data["member_ids"].to_a.map { |id| user_h[id].try(:name) }
        member_group_name = group_h[data["member_group_id"]].name rescue nil

        row = []
        row << data["year"]
        row << data["year_months"]["month"]
        row << data["name"]
        row << due_date
        row << due_start_on
        row << due_end_on
        row << category_name
        row << client_name
        row << cycle_name
        row << load_name
        row << member_names.join("\n")
        row << member_group_name
        y << encode_sjis(row.to_csv)
      end
    end
  end

  def aggregate_work_comment_enum_csv
    user_h = Gws::User.all.to_a.index_by(&:id)
    load_h = loads.index_by(&:id)

    group_pipeline = {
      _id: { user_id: "$user_id", work_id: "$work_id", year: "$year", month: "$month", day: "$day" },
      day_worktime_minutes: { "$sum" => "$worktime_minutes" }
    }
    lookup_pipeline = {
      from: "gws_workload_works",
      localField: "_id.work_id",
      foreignField: "_id",
      as: "works"
    }
    project_pipeline = {
      year: "$_id.year",
      month: "$_id.month",
      day: "$_id.day",
      user_id: "$_id.user_id",
      work: { "$arrayElemAt" => [ "$works", 0 ] },
      day_worktime_minutes: "$day_worktime_minutes"
    }

    pipes = []
    pipes << { "$match" => comments.selector }
    pipes << { "$match" => { "year" => year } }
    pipes << { "$group" => group_pipeline }
    pipes << { "$lookup" => lookup_pipeline }
    pipes << { "$project" => project_pipeline }

    aggregation = Gws::Workload::WorkComment.collection.aggregate(pipes).to_a

    Enumerator.new do |y|
      headers = %w(
        year month day
        work_name coefficient worktime_minutes
        user_id
        ).map { |key| Gws::Workload::WorkComment.t(key) }
      y << encode_sjis(headers.to_csv)

      aggregation.each do |data|
        hours = data["day_worktime_minutes"].to_i / 60
        minutes = data["day_worktime_minutes"].to_i % 60

        work_name = data["work"]["name"] rescue nil
        worktime_label = format("%d:%02d", hours, minutes)
        coefficient = load_h[data["work"]["load_id"]].coefficient rescue nil
        user_name = user_h[data["user_id"]].name rescue nil

        row = []
        row << data["year"]
        row << data["month"]
        row << data["day"]
        row << work_name
        row << coefficient
        row << worktime_label
        row << user_name
        y << encode_sjis(row.to_csv)
      end
    end
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
