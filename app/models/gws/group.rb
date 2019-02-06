class Gws::Group
  include SS::Model::Group
  include Gws::Referenceable
  include Gws::SitePermission
  include Gws::Addon::Schedule::GroupSetting
  include Gws::Addon::Facility::GroupSetting
  include Gws::Addon::Attendance::GroupSetting
  include Gws::Addon::Memo::GroupSetting
  include Gws::Addon::Circular::GroupSetting
  include Gws::Addon::Monitor::GroupSetting
  include Gws::Addon::Survey::GroupSetting
  include Gws::Addon::Board::GroupSetting
  include Gws::Addon::Faq::GroupSetting
  include Gws::Addon::Qna::GroupSetting
  include Gws::Addon::Discussion::GroupSetting
  include Gws::Addon::Share::GroupSetting
  include Gws::Addon::StaffRecord::GroupSetting
  include Gws::Addon::Elasticsearch::GroupSetting
  include Gws::Addon::System::FileSetting
  include Gws::Addon::System::MenuSetting
  include Gws::Addon::System::NoticeSetting
  include Gws::Addon::System::LogSetting
  include Gws::Addon::System::GroupSetting
  include Gws::Addon::History
  include Gws::Addon::Import::Group

  set_permission_name "gws_groups", :edit

  attr_accessor :cur_user, :cur_site

  has_many :users, foreign_key: :group_ids, class_name: "Gws::User"

  validate :validate_parent_name, if: ->{ cur_site.present? }

  scope :site, ->(site) { self.and name: /^#{::Regexp.escape(site.name)}(\/|$)/ }

  private

  def validate_parent_name
    return if cur_site.id == id

    if !name.start_with?("#{cur_site.name}/")
      errors.add :name, :not_a_child_group
    elsif name.scan('/').size > 1
      errors.add :base, :not_found_parent_group unless self.class.where(name: File.dirname(name)).exists?
    end
  end
end
