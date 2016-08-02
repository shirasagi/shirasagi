module Opendata::Common
  def get_url(url, page)
    url.sub(/\.html$/, "") + page
  end

  def get_app_url(app, page)
    app.url.sub(/\.html$/, "") + page
  end

  def get_app_full_url(app, page)
    app.full_url.sub(/\.html$/, "") + page
  end

  class << self
    public
      def limit_aggregation(model, pipes, limit)
        return model.collection.aggregate(pipes).to_a unless limit

        pipes << { "$limit" => limit + 1 }
        aggr = model.collection.aggregate(pipes).to_a

        def aggr.popped=(bool)
          @popped = bool
        end

        def aggr.popped?
          @popped.present?
        end

        if aggr.size > limit
          aggr.pop
          aggr.popped = true
        end
        aggr
      end

      def get_aggregate_field(model, name, opts = {})
        pipes = []
        pipes << { "$match" => model.where({}).selector.merge(name.to_s => { "$exists" => 1 }) }
        pipes << { "$group" => { _id: "$#{name}", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
        pipes << { "$sort" => { count: -1 } }
        limit_aggregation model, pipes, opts[:limit]
      end

      def get_aggregate_array(model, name, opts = {})
        pipes = []
        pipes << { "$match" => model.where({}).selector.merge(name.to_s => { "$exists" => 1 }) }
        pipes << { "$project" => { _id: 0, name.to_s => 1 } }
        pipes << { "$unwind" => "$#{name}" }
        pipes << { "$group" => { _id: "$#{name}", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
        pipes << { "$sort" => { count: -1 } }
        limit_aggregation model, pipes, opts[:limit]
      end

      def get_tag_list(model, query)
        pipes = []
        pipes << { "$match" => model.where({}).selector.merge("tags" => { "$exists" => 1 }) }
        pipes << { "$project" => { _id: 0, "tags" => 1 } }
        pipes << { "$unwind" => "$tags" }
        pipes << { "$group" => { _id: "$tags", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, name: "$_id", count: 1 } }
        pipes << { "$sort" => { name: 1 } }
        model.collection.aggregate(pipes).to_a
      end

      def get_tag(model, tag_name)
        pipes = []
        pipes << { "$match" => model.where({}).selector.merge("tags" => { "$exists" => 1 }) }
        pipes << { "$project" => { _id: 0, "tags" => 1 } }
        pipes << { "$unwind" => "$tags" }
        pipes << { "$group" => { _id: "$tags", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, name: "$_id", count: 1 } }
        pipes << { "$match" => { name: tag_name }}
        pipes << { "$sort" => { name: 1 } }
        model.collection.aggregate(pipes).to_a
      end

      def get_aggregate_resources(model, name, opts = {})
        pipes = []
        pipes << { "$match" => model.where({}).selector.merge("resources.#{name}" => { "$exists" => 1 }) }
        pipes << { "$project" => { _id: 0, "resources.#{name}" => 1 } }
        pipes << { "$unwind" => "$resources" }
        pipes << { "$group" => { _id: "$resources.#{name}", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
        pipes << { "$sort" => { count: -1 } }
        pipes << { "$limit" => 5 }
        limit_aggregation model, pipes, opts[:limit]
      end

  end
end
