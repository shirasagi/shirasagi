class Inquiry::Answer
  include SS::Document
  include SS::Reference::Site
  include SimpleCaptcha::ModelHelpers

  seqid :id
  field :node_id, type: Integer
  field :remote_addr, type: String
  field :user_agent, type: String

  belongs_to :node, foreign_key: :node_id, class_name: "Inquiry::Node::Form"
  embeds_many :data, class_name: "Inquiry::Answer::Data"

  permit_params :id, :node_id, :remote_addr, :user_agent, :captcha, :captcha_key

  apply_simple_captcha
  validates :node_id, presence: true
  validate :validate_data

  public
    def set_data(hash={})
      self.data = []
      hash.each do |key, value|
        value = value.kind_of?(Hash) ? value.map {|k, v| v}.join("\n") : value.to_s
        self.data << Inquiry::Answer::Data.new(column_id: key.to_i, value: value)
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
        if column.required?
          required_data = data.select { |d| column.id == d.column_id }.shift
          if required_data.blank? || required_data.value.blank?
            errors.add :base, "#{column.name}#{I18n.t('errors.messages.blank')}"
          end
        end
      end
    end
end
