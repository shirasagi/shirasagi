class Gws::Workflow2::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Workflow2::Inspection
  include Gws::Addon::Workflow2::Circulation
  # include SS::Addon::Markdown
  # include Gws::Addon::File
  include Gws::Addon::Workflow2::CustomForm
  include Gws::Addon::Workflow2::DestinationView
  include Gws::Addon::Workflow2::DestinationState
  include Gws::Addon::Workflow2::Approver
  include Gws::Addon::Workflow2::ApproverPrint
  include Gws::Workflow2::FilePermission
  include Gws::Addon::History
  include Gws::Workflow2::DestinationSetting

  cattr_reader(:approver_user_class) { Gws::User }
  self.show_history = false

  seqid :id
  field :name, type: String

  # permit_params :name

  validates :name, presence: true
  validate :validate_soft_delete, on: :soft_delete

  # after_clone_files :rewrite_file_ref

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::Workflow2FileJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::Workflow2FileJob.callback

  default_scope -> {
    order_by updated: -1
  }

  class << self
    SEARCH_HANDLERS = %i[search_keyword search_state search_destination_treat_state].freeze
    def search(params)
      criteria = all
      return criteria if params.blank?

      SEARCH_HANDLERS.each do |handler|
        criteria = criteria.send(handler, params)
      end
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, 'column_values.text_index')
    end

    def search_state(params)
      return all if params[:state].blank?

      # サブクエリ構築時に `unscoped` を用いているが、`unscoped` を呼び出すと現在の検索条件が消失してしまう。
      # それを防ぐため、前もって現在の検索条件を複製しておく。
      base_criteria = all.dup

      cur_site = params[:cur_site]
      cur_user = params[:cur_user]
      cur_user_group_ids = cur_user.groups.site(cur_site).pluck(:id)

      readable_conditions = build_readable_conditions(
        cur_site: cur_site, cur_user: cur_user, cur_user_group_ids: cur_user_group_ids)
      base_criteria = base_criteria.where('$and' => [{ '$or' => readable_conditions }])

      case params[:state]
      when 'all'
        base_criteria
      when 'approve'
        base_criteria.where(
          workflow_state: 'request',
          workflow_approvers: { '$elemMatch' => { user_id: cur_user.id, state: 'request' } }
        )
      when 'request'
        base_criteria.where('$and' => [{ '$or' => [{ workflow_user_id: cur_user.id }, { workflow_agent_id: cur_user.id }] }])
      when 'circulation'
        base_criteria.where(
          workflow_state: { '$in' => %w(approve approve_without_approval) },
          workflow_circulations: { '$elemMatch' => { user_id: cur_user.id, state: 'unseen' } }
        )
      when 'destination'
        base_criteria.where(
          workflow_state: { '$in' => %w(approve approve_without_approval) },
          '$and' => [
            { '$or' => [ { destination_group_ids: { "$in" => cur_user_group_ids } }, { destination_user_ids: cur_user.id }] }
          ]
        )
      else
        none
      end
    end

    def enum_csv(site: nil, encoding: "UTF-8")
      Gws::Workflow2::FileEnumerator.new(site, all, encoding: encoding)
    end

    def collect_attachments
      criteria = all.only(:_id, :file_ids, :column_values, :workflow_approvers, :workflow_circulations)
      attachment_ids = criteria.to_a.map(&:collect_attachment_ids)
      attachment_ids.flatten!
      return SS::File.none if attachment_ids.blank?

      SS::File.in(id: attachment_ids)
    end

    private

    def build_readable_conditions(cur_site:, cur_user:, cur_user_group_ids:)
      allow_selector = unscoped do
        all.allow(:read, cur_user, site: cur_site).selector
      end
      ret = [ allow_selector ]
      ret << { workflow_user_id: cur_user.id }
      ret << { workflow_agent_id: cur_user.id }
      ret << {
        workflow_state: { '$in' => %w(request approve approve_without_approval remand) },
        workflow_approvers: { '$elemMatch' => { user_id: cur_user.id, state: { '$in' => %w(request pending approve remand) } } }
      }
      ret << {
        workflow_state: { '$in' => %w(approve approve_without_approval) },
        workflow_circulations: { '$elemMatch' => { user_id: cur_user.id, state: { '$in' => %w(seen unseen) } } }
      }
      ret << {
        workflow_state: { '$in' => %w(approve approve_without_approval) },
        destination_user_ids: cur_user.id
      }
      ret << {
        workflow_state: { '$in' => %w(approve approve_without_approval) },
        destination_group_ids: { "$in" => cur_user_group_ids }
      }
      ret
    end
  end

  # rubocop:disable Rails::Pluck
  def reminder_user_ids
    ids = [@cur_user.id, user_id]
    ids << workflow_user_id
    ids += workflow_approvers.map { |m| m[:user_id] }
    ids.uniq.compact
  end
  # rubocop:enable Rails::Pluck

  alias state workflow_state

  def workflow_state_options
    %w(all approve request circulation destination).map do |v|
      [I18n.t("gws/workflow.options.file_state.#{v}"), v]
    end
  end

  def readable?(user, site:)
    return true if allowed?(:read, user, site: site, adds_error: false)
    return true if workflow_user_id == user.id || workflow_agent_id == user.id
    return true if readable_in_approvers?(user, site: site)
    return true if readable_in_circulations?(user, site: site)
    return true if readable_in_destination?(user, site: site)
    false
  end

  def readable_in_approvers?(user, site:)
    return false unless %w(request approve approve_without_approval remand).include?(workflow_state)

    available_states = %w(request pending approve remand)
    workflow_approvers.any? do |approver|
      next false if approver[:user_id] != user.id

      state = approver[:state]
      next false if state.blank?

      available_states.include?(state)
    end
  end

  def readable_in_circulations?(user, site:)
    return false if workflow_state != "approve" && workflow_state != "approve_without_approval"

    available_states = %w(seen unseen)
    workflow_circulations.any? do |circulation|
      next false if circulation[:user_id] != user.id

      state = circulation[:state]
      next false if state.blank?

      available_states.include?(state)
    end
  end

  def readable_in_destination?(user, site:)
    return false if workflow_state != "approve" && workflow_state != "approve_without_approval"

    return true if destination_user_ids.include?(user.id)
    return true if user.groups.site(site).pluck(:id).any? { |group_id| destination_group_ids.include?(group_id) }
    false
  end

  def editable?(user, site:)
    if workflow_editable_state?
      return true if allowed?(:edit, user, site: site, adds_error: false)
      return true if workflow_user_id == user.id || workflow_agent_id == user.id
    end
    return true if workflow_requested? && workflow_approver_editable?(user)
    false
  end

  def destroyable?(user, site:)
    if workflow_editable_state?
      return true if allowed?(:delete, user, site: site, adds_error: false)
      return true if workflow_user_id == user.id || workflow_agent_id == user.id
    end
    false
  end

  # override Gws::Addon::Reminder#reminder_url
  def reminder_url(*args)
    #ret = super
    name = reference_model.tr('/', '_') + '_readable_path'
    ret = [name, id: id]
    options = ret.extract_options!
    options[:state] = 'all'
    options[:site] = site_id
    [ *ret, options ]
  end

  def enum_csv(encoding: "Shift_JIS")
    Gws::Workflow2::FileEnumerator.new(@cur_site || site, [ self ], encoding: encoding)
  end

  def collect_attachment_ids
    attachment_ids = []

    # attachment_ids += file_ids if file_ids.present?

    if column_values.present?
      column_values.each do |value|
        if value.is_a?(Gws::Column::Value::FileUpload) && value.file_ids.present?
          attachment_ids += value.file_ids
        end
      end
    end

    attachment_ids += workflow_approvers.filter_map { |approver| approver[:file_ids] }.flatten
    attachment_ids += workflow_circulations.filter_map { |circulation| circulation[:file_ids] }.flatten
    attachment_ids.compact!
    attachment_ids.uniq!
    attachment_ids
  end

  def collect_attachments
    attachment_ids = collect_attachment_ids
    return SS::File.none if attachment_ids.blank?

    SS::File.in(id: attachment_ids)
  end

  def agent_enabled?
    return false if form.blank?

    form.agent_enabled?
  end

  def new_flag?
    created > Time.zone.now - site.workflow_new_days.day
  end

  def route_my_group_alternate?
    form.try(:default_route_id) == "my_group_alternate"
  end

  private

  def validate_soft_delete
    if @cur_user && @cur_site && !destroyable?(@cur_user, site: @cur_site)
      errors.add :base, :unable_to_delete
    end
  end

  # def rewrite_file_ref
  #   text = self.text
  #   return if text.blank?
  #
  #   in_clone_file.each do |old_id, new_id|
  #     old_file = SS::File.find(old_id) rescue nil
  #     new_file = SS::File.find(new_id) rescue nil
  #     next if old_file.blank? || new_file.blank?
  #
  #     text.gsub!(old_file.url.to_s, new_file.url.to_s)
  #     text.gsub!(old_file.thumb_url.to_s, new_file.thumb_url.to_s) if old_file.thumb.present? && new_file.thumb.present?
  #   end
  #
  #   self.text = text
  # end
end
