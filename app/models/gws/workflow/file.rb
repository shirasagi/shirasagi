class Gws::Workflow::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  #include Gws::Addon::Reminder
  include ::Workflow::Addon::Approver
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Workflow::CustomForm
  include Gws::Addon::Workflow::ApproverPrint
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  cattr_reader(:approver_user_class) { Gws::User }

  seqid :id
  field :state, type: String, default: 'closed'
  field :name, type: String

  permit_params :state, :name

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  after_clone_files :rewrite_file_ref

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::WorkflowFileJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::WorkflowFileJob.callback

  default_scope -> {
    order_by updated: -1
  }

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

      all.keyword_in(params[:keyword], :name, :text, 'column_values.text_index')
    end

    def search_state(params)
      return all if params[:state].blank?

      # サブクエリ構築時に `unscoped` を用いているが、`unscoped` を呼び出すと現在の検索条件が消失してしまう。
      # それを防ぐため、前もって現在の検索条件を複製しておく。
      base_criteria = all.dup

      cur_site = params[:cur_site]
      cur_user = params[:cur_user]

      allow_selector = unscoped do
        all.allow(:read, cur_user, site: cur_site).selector
      end
      readable_selector = unscoped do
        all.in(state: %w(approve public)).readable(cur_user, site: cur_site).selector
      end
      base_criteria = base_criteria.where('$and' => [{ '$or' => [ allow_selector, readable_selector ] }])

      case params[:state]
      when 'all'
        base_criteria
      when 'approve'
        base_criteria.where(
          workflow_state: 'request',
          workflow_approvers: { '$elemMatch' => { 'user_id' => cur_user.id, 'state' => 'request' } }
        )
      when 'request'
        base_criteria.where(workflow_user_id: cur_user.id)
      else
        none
      end
    end

    def enum_csv(site: nil, encoding: "Shift_JIS")
      Gws::Workflow::FileEnumerator.new(site, all, encoding: encoding)
    end

    def collect_attachments
      attachment_ids = []

      attachment_ids += all.pluck(:file_ids).flatten.compact

      all.pluck(:column_values).flatten.compact.each do |bson_doc|
        if bson_doc["_type"] == Gws::Column::Value::FileUpload.name
          attachment_ids += bson_doc["file_ids"] if bson_doc["file_ids"].present?
        end
      end

      attachment_ids += all.pluck(:workflow_approvers).compact.flatten.map { |bson_doc| bson_doc["file_ids"] }.compact.flatten
      attachment_ids += all.pluck(:workflow_circulations).compact.flatten.map { |bson_doc| bson_doc["file_ids"] }.compact.flatten
      return SS::File.none if attachment_ids.blank?

      SS::File.in(id: attachment_ids)
    end
  end

  def reminder_user_ids
    ids = [@cur_user.id, user_id]
    ids << workflow_user_id
    ids += workflow_approvers.map { |m| m[:user_id] }
    ids.uniq.compact
  end

  def status
    if state == 'approve'
      state
    elsif workflow_state.present?
      workflow_state
    elsif state == 'closed'
      'draft'
    else
      state
    end
  end

  def workflow_state_options
    %w(all approve request).map do |v|
      [I18n.t("gws/workflow.options.file_state.#{v}"), v]
    end
  end

  def editable?(user, opts)
    editable = allowed?(:edit, user, opts) && !workflow_requested?
    return editable if editable

    if workflow_requested?
      workflow_approver_editable?(user)
    end
  end

  def destroyable?(user, opts)
    allowed?(:delete, user, opts) && !workflow_requested?
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
    Gws::Workflow::FileEnumerator.new(@cur_site || site, [ self ], encoding: encoding)
  end

  def collect_attachments
    attachment_ids = []

    attachment_ids += file_ids if file_ids.present?

    if column_values.present?
      column_values.each do |value|
        if value.is_a?(Gws::Column::Value::FileUpload)
          attachment_ids += value.file_ids if value.file_ids.present?
        end
      end
    end

    attachment_ids += workflow_approvers.map { |approver| approver[:file_ids] }.compact.flatten
    attachment_ids += workflow_circulations.map { |circulation| circulation[:file_ids] }.compact.flatten
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

  private

  def rewrite_file_ref
    text = self.text
    return if text.blank?

    in_clone_file.each do |old_id, new_id|
      old_file = SS::File.find(old_id) rescue nil
      new_file = SS::File.find(new_id) rescue nil
      next if old_file.blank? || new_file.blank?

      text.gsub!(old_file.url.to_s, new_file.url.to_s)
      text.gsub!(old_file.thumb_url.to_s, new_file.thumb_url.to_s) if old_file.thumb.present? && new_file.thumb.present?
    end

    self.text = text
  end
end
