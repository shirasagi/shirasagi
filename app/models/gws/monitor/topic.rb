class Gws::Monitor::Topic
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::GroupPermission

  field :name, type: String
  field :due_date, type: DateTime
  field :admin_setting, type: String, default: '1'
  field :spec_config, type: String, default: '0'
  field :reminder_start_section, type: String, default: '0'
  field :state, type: String, default: 'preparation'

  permit_params :name, :due_date, :admin_setting, :spec_config, :reminder_start_section, :state

  validates :name, presence: true

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?
    criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
    criteria
  }

  def admin_setting_options
    [
        ['作成者が管理する', '1'],
        ['所属で管理する', '0']
    ]
  end

  def spec_config_options
    [
        ['回答者のみ表示する', '0'],
        ['他の回答者名を表示する', '3'],
        ['他の回答者名と内容を表示する', '5']
    ]
  end

  def reminder_start_section_options
    [
        ['配信直後から表示する', '0'],
        ['配信日から1日後に表示', '-1'],
        ['配信日から2日後に表示', '-2'],
        ['配信日から3日後に表示', '-3'],
        ['配信日から4日後に表示', '-4'],
        ['配信日から5日後に表示', '-5'],
        ['回答期限日の1日前から表示', '1'],
        ['回答期限日の2日前から表示', '2'],
        ['回答期限日の3日前から表示', '3'],
        ['回答期限日の4日前から表示', '4'],
        ['回答期限日の5日前から表示', '5'],
        ['表示しない', '-999']
    ]
  end

  class << self
    def sort_options
      [
          ['更新日順', 'sort1'],
      ]
    end
  end
end