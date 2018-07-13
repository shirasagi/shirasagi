class Gws::Questionnaire::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Questionnaire::CustomForm
  # include Gws::Addon::Member
  # include Gws::Addon::Schedules
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # member_ids_optional

  attr_accessor :in_skip_notification_mail

  seqid :id
  # field :state, type: String, default: 'closed'
  field :name, type: String

  permit_params :name

  # validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :name, presence: true, length: { maximum: 80 }
  # after_save :send_notification_mail, unless: ->{ @in_skip_notification_mail }

  # scope :and_public, -> { where(state: 'public') }
  # scope :and_closed, -> { where(state: 'closed') }

  # # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::ReportFileJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::ReportFileJob.callback

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      # criteria = criteria.search_state(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, 'column_values.text_index')
    end

    # def search_state(params)
    #   return all if params[:state].blank? || params[:cur_site].blank? || params[:cur_user].blank?
    #
    #   # サブクエリ構築時に `unscoped` を用いているが、`unscoped` を呼び出すと現在の検索条件が消失してしまう。
    #   # それを防ぐため、前もって現在の検索条件を複製しておく。
    #   base_criteria = all.dup
    #
    #   cur_site = params[:cur_site]
    #   cur_user = params[:cur_user]
    #   case params[:state]
    #   when 'inbox'
    #     base_criteria.and_public.member(cur_user)
    #   when 'sent'
    #     base_criteria.and_public.allow(:read, cur_user, site: cur_site)
    #   when 'closed'
    #     base_criteria.and_closed.allow(:read, cur_user, site: cur_site)
    #   when 'readable'
    #     member_selector = unscoped.member(cur_user).selector
    #     readable_selector = unscoped.readable(cur_user, site: cur_site).selector
    #     base_criteria.and_public.ne(user_id: cur_user.id).where('$and' => [{ '$or' => [ member_selector, readable_selector ] }])
    #   when 'redirect'
    #     member_selector = unscoped.member(cur_user).selector
    #     readable_selector = unscoped.readable(cur_user, site: cur_site).selector
    #     allow_selector = unscoped.allow(:read, cur_user, site: cur_site).selector
    #     base_criteria.where('$and' => [{ '$or' => [ member_selector, readable_selector, allow_selector ] }])
    #   else
    #     none
    #   end
    # end

    def enum_csv(params)
      Gws::Questionnaire::FileEnumerator.new(self, params)
    end

    def aggregate
      select_like_columns = [ Gws::Column::Value::CheckBox, Gws::Column::Value::RadioButton, Gws::Column::Value::Select ]

      pipes = []
      pipes << { "$match" => self.all.selector }
      pipes << { "$unwind" => "$column_values" }
      pipes << { "$match" => { "column_values._type" => { "$in" => select_like_columns.map(&:name) } } }
      pipes << {
        "$project" => {
          "column_values.column_id" => 1,
          "column_values.values" => { "$ifNull" => [ "$column_values.values", [ "$column_values.value" ] ] }
        }
      }
      pipes << { "$unwind" => "$column_values.values" }
      pipes << {
        "$group" => {
          _id: { "column_id" => "$column_values.column_id", "value" => "$column_values.values" },
          count: { "$sum"=> 1 }
        }
      }

      self.collection.aggregate(pipes).to_a
    end
  end

  # def state_options
  #   %w(public closed).map do |v|
  #     [ I18n.t("gws/report.options.file_state.#{v}"), v ]
  #   end
  # end

  # def public?
  #   state == 'public'
  # end

  # def closed?
  #   !public?
  # end

  # # override Gws::Addon::Reminder#reminder_url
  # def reminder_url(*args)
  #   #ret = super
  #   name = reference_model.tr('/', '_') + '_readable_path'
  #   ret = [name, id: id]
  #   options = ret.extract_options!
  #   options[:state] = 'all'
  #   options[:site] = site_id
  #   [ *ret, options ]
  # end

  # private

  # def send_notification_mail
  #   added_member_ids = removed_member_ids = []
  #
  #   if state == 'public'
  #     cur_member_ids = sorted_overall_members.pluck(:id)
  #     prev_member_ids = sorted_overall_members_was.pluck(:id)
  #
  #     if state_was == 'closed'
  #       # just published
  #       added_member_ids = cur_member_ids
  #       removed_member_ids = []
  #     else
  #       added_member_ids = cur_member_ids - prev_member_ids
  #       removed_member_ids = prev_member_ids - cur_member_ids
  #     end
  #   end
  #
  #   if state == 'closed' && state_was == 'public'
  #     # just depublished
  #     cur_member_ids = sorted_overall_members.pluck(:id)
  #     prev_member_ids = sorted_overall_members_was.pluck(:id)
  #
  #     added_member_ids = []
  #     removed_member_ids = (cur_member_ids + prev_member_ids).uniq
  #   end
  #
  #   return if added_member_ids.blank? && removed_member_ids.blank?
  #
  #   job = Gws::Report::NotificationJob.bind(site_id: @cur_site || site)
  #   job.perform_now(id.to_s, added_member_ids, removed_member_ids)
  # end
end
