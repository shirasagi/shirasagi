module SS::Model::Group
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Ldap::Addon::Group

  attr_accessor :in_password

  included do
    store_in collection: "ss_groups"
    index({ name: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :order, type: Integer
    permit_params :name, :order

    default_scope -> { order_by(order: 1, name: 1) }

    validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
    validate :validate_name
    after_save :rename_children, if: ->{ @db_changes }
  end

  module ClassMethods
    public
      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.search_text params[:name]
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name
        end
        criteria
      end
  end

  private
    def validate_name
      if name =~ /\/$/ || name =~ /^\// || name =~ /\/\//
        errors.add :name, :invalid
      end
    end

  public
    def full_name
      name.tr("/", " ")
    end

    def trailing_name
      name.split("/").pop
    end

    def rename_children
      return unless @db_changes["name"]
      return unless @db_changes["name"][0]
      return unless @db_changes["name"][1]

      src = @db_changes["name"][0]
      dst = @db_changes["name"][1]

      SS::Group.where(name: /^#{Regexp.escape(src)}\//).each do |item|
        item.name = item.name.sub(/^#{Regexp.escape(src)}\//, "#{dst}\/")
        item.save validate: false
      end
    end

    def root
      parts = name.try(:split, "/") || []
      return self if parts.length <= 1

      0.upto(parts.length - 1) do |c|
        ret = self.class.where(name: parts[0..c].join("/")).first
        return ret if ret.present?
      end
      nil
    end

    def root?
      id == root.id
    end

    def descendants
      self.class.where(name: /^#{name}\//)
    end
end
