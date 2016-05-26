class Inquiry::Answer
  include SS::Document
  include SS::Reference::Site
  include SimpleCaptcha::ModelHelpers

  attr_accessor :cur_node

  seqid :id
  field :node_id, type: Integer
  field :remote_addr, type: String
  field :user_agent, type: String
  field :source_url, type: String
  field :source_name, type: String

  belongs_to :node, foreign_key: :node_id, class_name: "Inquiry::Node::Form"
  embeds_many :data, class_name: "Inquiry::Answer::Data"

  permit_params :id, :node_id, :remote_addr, :user_agent, :captcha, :captcha_key

  apply_simple_captcha

  before_validation :set_node, if: ->{ cur_node.present? }
  before_validation :copy_contents_info
  validates :node_id, presence: true
  validate :validate_data

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :source_url, :source_name, "data.values"
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

      criteria
    end

    def find_node(site, source_url)
      return if source_url.blank?
      path = source_url
      path = path[1..-1] if path.start_with?("/")

      Cms::Node.site(site).in_path(path).sort(depth: -1).first
    end

    def find_page(site, source_url)
      return if source_url.blank?
      path = source_url
      path = path[1..-1] if path.start_with?("/")

      Cms::Page.site(site).filename(path).first
    end

    def find_content(site, source_url)
      find_page(site, source_url) || find_node(site, source_url)
    end
  end

  def set_data(hash = {})
    self.data = []
    hash.each do |key, data|
      value, confirm = data
      if value.kind_of?(Hash)
        values = value.values
        value  = value.map {|k, v| v}.join("\n")
      else
        values = [value.to_s]
        value  = value.to_s
      end

      self.data << Inquiry::Answer::Data.new(column_id: key.to_i, value: value, values: values, confirm: confirm)
    end
  end

  def data_summary
    summary = ""
    data.each do |d|
      summary << "#{d.value} "
    end
    summary.gsub(/\s+/, ", ").gsub(/, $/, "").truncate(80)
  end

  def source_content
    self.class.find_content(@cur_site, source_url)
  end

  def source_full_url
    if source_url.present?
      uri = URI.parse(site.full_url)
      uri.path = source_url
      uri.to_s
    end
  end

  private
    def validate_data
      columns = Inquiry::Column.where(site_id: site_id, node_id: node_id, state: "public").order_by(order: 1)
      columns.each do |column|
        column.validate_data(self, data.select { |d| column.id == d.column_id }.shift)
      end
    end

    def set_node
      self.node_id = cur_node.id
    end

    def copy_contents_info
      source = source_content
      return if source.blank?

      self.source_name = source.name
    end
end
