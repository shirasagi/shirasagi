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
    find_page || find_node
  end

  private
    def validate_data
      columns = Inquiry::Column.where(node_id: self.node_id, state: "public").order_by(order: 1)
      columns.each do |column|
        column.validate_data(self, data.select { |d| column.id == d.column_id }.shift)
      end
    end

    def set_node
      self.node_id = cur_node.id
    end

    def find_node
      return if source_url.blank?
      path = source_url
      path = path[1..-1] if path.start_with?("/")

      Cms::Node.site(@cur_site).in_path(path).sort(depth: -1).first
    end

    def find_page
      return if source_url.blank?
      path = source_url
      path = path[1..-1] if path.start_with?("/")

      Cms::Page.site(@cur_site).filename(path).first
    end

    def copy_contents_info
      source = source_content
      return if source.blank?

      self.source_name = source.name
    end
end
