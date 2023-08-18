class Gws::CustomGroup
  include SS::Model::CustomGroup
  include SS::Fields::Normalizer
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Import::CustomGroup

  # Member addon setting
  keep_members_order

  set_permission_name "gws_custom_groups"

  validate :validate_parent_name, if: ->{ cur_site.present? }

  private

  def validate_presence_member
    # skip
  end

  def validate_parent_name
    return if cur_site.id == id

    if name.scan('/').present?
      errors.add :base, :not_found_parent_group unless self.class.where(name: File.dirname(name)).exists?
    end
  end
end
