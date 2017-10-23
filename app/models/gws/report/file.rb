class Gws::Report::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Reminder
  include Gws::Addon::Report::CustomForm
  include Gws::Addon::Member
  include Gws::Addon::Schedules
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  member_ids_optional

  seqid :id
  field :state, type: String, default: 'closed'
  field :name, type: String

  permit_params :name

  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :name, presence: true, length: { maximum: 80 }

  scope :and_public, -> { where(state: 'public') }
  scope :and_closed, -> { where(state: 'closed') }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_state(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_state(params)
      return all if params[:state].blank? || params[:cur_site].blank? || params[:cur_user].blank?

      cur_site = params[:cur_site]
      cur_user = params[:cur_user]
      case params[:state]
      when 'inbox'
        conds = [{ member_ids: cur_user.id }]
        custom_group_ids = Gws::CustomGroup.site(cur_site).member(cur_user).pluck(:id)
        if custom_group_ids.present?
          conds << { :member_custom_group_ids.in => custom_group_ids }
        end
        all.and_public.where('$and' => [{ '$or' => conds }])
      when 'sent'
        all.and_public.where(user_id: cur_user.id)
      when 'closed'
        all.and_closed.where(user_id: cur_user.id)
      else
        all.readable(cur_user, site: cur_site)
      end
    end
  end

  def state_options
    %w(public closed).map do |v|
      [ I18n.t("gws/report.options.file_state.#{v}"), v ]
    end
  end

  def public?
    state == 'public'
  end

  def closed?
    !public?
  end

  # override Gws::Addon::Reminder#reminder_url
  def reminder_url(*args)
    ret = super
    options = ret.extract_options!
    options[:state] = 'all'
    [ *ret, options ]
  end
end
