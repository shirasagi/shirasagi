module SS::Group::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  attr_accessor :in_password

  included do
    store_in collection: "ss_groups"

    seqid :id
    field :name, type: String
    permit_params :name

    validates :name, presence: true, length: { maximum: 80 }
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
      name.gsub("/", " ")
    end

    def rename_children
      return unless @db_changes["name"]
      return unless @db_changes["name"][0]
      return unless @db_changes["name"][1]

      src = @db_changes["name"][0]
      dst = @db_changes["name"][1]

      SS::Group.where(name: /^#{src}\//).each do |item|
        item.name = item.name.sub(/^#{src}\//, "#{dst}\/")
        item.save validate: false
      end
    end
end
