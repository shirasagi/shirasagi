class Inquiry::Answer
  include SS::Document
  include SS::Reference::Site
  include SimpleCaptcha::ModelHelpers

  attr_accessor :cur_node
  attr_accessor :in_source_node, :in_source_page

  seqid :id
  field :node_id, type: Integer
  field :remote_addr, type: String
  field :user_agent, type: String

  belongs_to :node, foreign_key: :node_id, class_name: "Inquiry::Node::Form"
  embeds_many :data, class_name: "Inquiry::Answer::Data"
  belongs_to :source_node, class_name: "Cms::Node"
  belongs_to :source_page, class_name: "Cms::Page"

  permit_params :id, :node_id, :remote_addr, :user_agent, :captcha, :captcha_key

  apply_simple_captcha

  before_validation :set_node, if: ->{ cur_node.present? }
  before_validation :set_source_node, if: ->{ in_source_node.present? }
  before_validation :set_source_page, if: ->{ in_source_page.present? }
  validates :node_id, presence: true
  validate :validate_data

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

    def set_source_node
      path = in_source_node
      path = path[1..-1] if path.start_with?("/")

      node = Cms::Node.site(@cur_site).in_path(path).sort(depth: -1).first
      self.source_node_id = node.id if node.present?
    end

    def set_source_page
      path = in_source_page
      path = path[1..-1] if path.start_with?("/")

      page = Cms::Page.site(@cur_site).filename(path).first
      self.source_page_id = page.id if page.present?
    end
end
