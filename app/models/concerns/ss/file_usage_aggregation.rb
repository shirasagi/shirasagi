module SS::FileUsageAggregation
  extend ActiveSupport::Concern

  module ClassMethods
    def aggregate_files_used
      criteria = all
      return 0 unless criteria.exists?

      pipes = []
      pipes << { '$match' => criteria.selector }
      pipes << {
        '$lookup' => {
          from: criteria.klass.collection_name.to_s,
          localField: "_id",
          foreignField: "original_id",
          as: "thumb"
        }
      }
      pipes << {
        '$project' => {
          size: { '$sum' => ['$size', { '$sum' => '$thumb.size' }] }
        }
      }
      pipes << {
        '$group' => {
          _id: nil,
          size: { '$sum' => '$size' }
        }
      }

      criteria.klass.collection.aggregate(pipes).first.try(:[], :size) || 0
    end
  end
end
