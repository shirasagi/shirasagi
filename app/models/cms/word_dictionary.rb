class Cms::WordDictionary
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_tools", :use

  # field separator
  FS = %w(, 、 ，).freeze

  seqid :id
  field :name, type: String
  field :body, type: String

  permit_params :name, :body

  validates :name, presence: true
  validates :body, presence: true
  validate :validate_body

  def validate_body
    body.split(/\n/).each_with_index do |line, idx|
      line = line.to_s.gsub(/#.*/, "")
      from_to = line.split(/[#{FS.join}]/).map(&:strip)
      from, to = from_to

      next if from_to.size == 2 && from.present? && to.present?
      errors.add :base, :malformed_kana_dictionary, line: line, no: idx + 1
    end
  end

  def to_a
    body.split(/\n/).map do |line|
      line = line.to_s.gsub(/#.*/, "")
      from_to = line.split(/[#{FS.join}]/).map(&:strip)
      from, to = from_to

      next from_to if from_to.size == 2 && from.present? && to.present?
      nil
    end.compact
  end

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :body
      end
      criteria
    end

    def to_config
      h = {}
      h[:replace_words] = criteria.map(&:to_a).flatten(1).to_h
      h
    end
  end
end
