module Chorg::Model::Revision
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Voice::Lockable

  included do
    attr_accessor :add_newly_created_group_to_site

    seqid :id
    field :name, type: String
    field :job_ids, type: Array

    permit_params :name, :changesets, :add_newly_created_group_to_site

    validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :site_id }

    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    }
  end

  def add_changesets
    changesets.select { |e| e.type == Chorg::Model::Changeset::TYPE_ADD }
  end

  def move_changesets
    changesets.select { |e| e.type == Chorg::Model::Changeset::TYPE_MOVE }
  end

  def unify_changesets
    changesets.select { |e| e.type == Chorg::Model::Changeset::TYPE_UNIFY }
  end

  def division_changesets
    changesets.select { |e| e.type == Chorg::Model::Changeset::TYPE_DIVISION }
  end

  def delete_changesets
    changesets.select { |e| e.type == Chorg::Model::Changeset::TYPE_DELETE }
  end
end
