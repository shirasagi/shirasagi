class Recommend::SimilarityScore
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  index({ score: -1 })

  seqid :id
  field :key, type: String
  field :path, type: String
  field :score, type: Float

  validates :key, presence: true
  validates :path, presence: true
  validates :score, presence: true

  default_scope { order(score: -1) }

  set_permission_name "cms_sites", :edit

  def content
    filename = path.sub(/^\//, "")
    page = Cms::Page.site(site).where(filename: filename).first
    return page if page

    filename = filename.sub(/\/index\.html$/, "")
    node = Cms::Node.site(site).where(filename: filename).first
    return node if node

    return nil
  end

  class << self
    def similarity(key)
      self.and([
        { :score.gt => 0.0 },
        { :key => key },
      ])
    end

    def exclude_paths(paths)
      return all if paths.blank?

      paths = paths.select(&:present?)
      return all if paths.blank?

      all.where(path: { "$nin" => paths })
    end

    def to_key_axis_aggregation(match = {})
      pipes = []
      pipes << { "$match" => match } if match.present?
      pipes << { "$sort" => { "score" => -1, "key" => -1 } }
      pipes << { "$group" =>
        {
          "_id" => { "key" => "$key" },
          "scores" => {
            "$push" => {
              "path" => "$path",
              "score" => "$score"
            }
          }
        }}
      aggregation = self.collection.aggregate(pipes)

      prefs = {}
      aggregation = aggregation.each do |i|
        key = i["_id"]["key"]

        scores = {}
        i["scores"].each do |h|
          path = h["path"]
          score = h["score"]
          scores[path] = score
        end

        prefs[key] = scores
      end

      prefs
    end
  end
end
