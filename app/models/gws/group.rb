class Gws::Group
  include SS::Model::Group
  include Gws::SitePermission

  set_permission_name "gws_groups", :edit

  attr_accessor :cur_site

  has_many :users, foreign_key: :group_ids, class_name: "Gws::User"

  validate :validate_parent_name, if: ->{ cur_site.present? }

  scope :site, ->(site) { where name: /^#{Regexp.escape(site.name)}(\/|$)/ }

  private
    def validate_parent_name
      return if cur_site.id == id

      if name !~ /^#{Regexp.escape(cur_site.name)}\//
        errors.add :name, :not_a_child_group
      elsif name.scan('/').size > 1
        errors.add :base, :not_found_parent_group unless self.class.where(name: File.dirname(name)).exists?
      end
    end
end
