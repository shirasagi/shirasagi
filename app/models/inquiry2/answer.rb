class Inquiry2::Answer
  include SS::Document
  include SS::Reference::Site
  include Inquiry2::Addon::Answer::Body
  include Inquiry2::Addon::CustomForm
  include Inquiry2::Addon::CustomForm2
  include Cms::Addon::GroupPermission

  attr_accessor :cur_node

  store_in_default_post
  set_permission_name "inquiry_answers"

  seqid :id
  belongs_to :node, class_name: "Inquiry2::Node::Form"
  field :remote_addr, type: String
  field :user_agent, type: String
  field :source_url, type: String
  field :source_name, type: String

  field :closed, type: DateTime, default: nil
  field :state, type: String, default: "open"
  field :comment, type: String
  field :inquiry2_page_url, type: String
  field :inquiry2_page_name, type: String

  belongs_to :member, class_name: "Cms::Member"

  permit_params :id, :node_id, :remote_addr, :user_agent
  permit_params :state, :comment, :inquiry2_page_url, :inquiry2_page_name

  before_validation :set_node, if: ->{ cur_node.present? }
  before_validation :set_closed
  before_validation :copy_contents_info
  validates :node_id, presence: true

  # before_save :update_file_data
  # before_destroy :delete_file_data

  scope :state, ->(state) {
    return where({}) if state.blank? || state == 'all'
    return where(:state.ne => 'closed') if state == 'unclosed'
    where(state: state)
  }

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :source_url, :source_name, :comment,
          "column_values.name", "column_values.value"
      end

      if params[:year].present?
        year = params[:year].to_i
        if params[:month].present?
          month = params[:month].to_i
          sdate = Date.new year, month, 1
          edate = sdate + 1.month
        else
          sdate = Date.new year, 1, 1
          edate = sdate + 1.year
        end

        criteria = criteria.where("updated" => { "$gte" => sdate, "$lt" => edate })
      end

      if params[:url].present?
        criteria = criteria.where(source_url: /^#{::Regexp.escape(params[:url])}/)
      elsif params[:feedback]
        criteria = criteria.where(source_url: { "$exists" => true, "$ne" => nil })
      end

      if params[:group].present?
        criteria = criteria.in(group_ids: params[:group].to_i)
      end

      criteria
    end

    def find_node(site, source_url)
      return if source_url.blank?
      path = source_url
      path = path.sub(/^#{site.url}/, "")
      Cms::Node.site(site).in_path(path).order_by(depth: -1).first
    end

    def find_page(site, source_url)
      return if source_url.blank?
      path = source_url
      path = path.sub(/^#{site.url}/, "")
      Cms::Page.site(site).filename(path).first
    end

    def find_content(site, source_url)
      find_page(site, source_url) || find_node(site, source_url)
    end
  end

  def find_data(column)
    data.select { |d| d.column_id == column.id }.first
  end

  def data_summary
    summary = []
    column_values.each do |column|
      summary << column.value
    end
    summary.join(', ').truncate(80).presence || I18n.t('inquiry2.answer')
  end

  def source_content
    self.class.find_content(@cur_site || site, source_url)
  end

  def source_full_url
    if source_url.present?
      uri = ::Addressable::URI.parse(site.full_url)
      uri.path = source_url
      uri.to_s
    end
  end

  def inquiry2_page_content
    self.class.find_content(@cur_site || site, inquiry2_page_url)
  end

  def inquiry2_page_full_url
    if inquiry2_page_url.present?
      uri = ::Addressable::URI.parse(site.full_url)
      uri.path = inquiry2_page_url
      uri.to_s
    end
  end

  def state_options
    I18n.t("inquiry2.options.answer_state").map { |k, v| [v, k] }
  end

  def search_state_options
    I18n.t("inquiry2.options.search_answer_state").map { |k, v| [v, k] }
  end

  private

  def set_node
    self.node_id = cur_node.id
  end

  def set_closed
    self.closed = (state == "closed") ? Time.zone.now : nil
  end

  def copy_contents_info
    source = source_content
    return if source.blank?

    self.source_name = source.name
  end

  def each_file_data(&block)
    self.data.select do |data|
      column = data.column
      next if column.blank?

      next if column.input_type != "upload_file"

      yield data
    end
  end

  def update_file_data
    each_file_data do |data|
      file_id = data.values[0]
      next if file_id.blank?

      file = SS::File.find(file_id) rescue nil
      next if file.blank?

      file.model = "inquiry2/answer"
      file.owner_item = self
      file.save
    end
  end

  def delete_file_data
    each_file_data do |data|
      file_id = data.values[0]
      next if file_id.blank?

      file = SS::File.find(file_id) rescue nil
      next if file.blank?
      next if file.model != "inquiry2/answer"

      file.destroy
    end
  end
end
