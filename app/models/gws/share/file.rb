class Gws::Share::File
  include SS::Model::File
  include Gws::Reference::Site
  include Gws::Addon::Share::Category
  include Gws::Addon::GroupPermission

  validates :category_ids, presence: true

  default_scope ->{ where(model: "share/file") }

  class << self
    def search(params)
      criteria = super
      return criteria if params.blank?

      if params[:category].present?
        category_ids = Gws::Share::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
        criteria = criteria.in(category_ids: category_ids)
      end

      criteria
    end
  end

  def remove_public_file
    #TODO: fix SS::Model::File
  end

  private
    def validate_size
      super

      limit = cur_site.share_max_file_size || 0
      return if limit <= 0

      if in_file.present?
        size = in_file.size
      elsif in_files.present?
        size = in_files.map(&:size).max || 0
      else
        return
      end

      if size > limit
        errors.add(:base, :file_size_exceeds_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
      end
    end
end
