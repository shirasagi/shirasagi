class Opendata::Comment
  include SS::Document

  seqid :id
  field :name, type: String
  field :text, type: String

  embedded_in :idea, class_name: "Opendata::Idea", inverse_of: :comment

  permit_params :name, :text

  validates :name, presence: true

  after_save -> { idea.save(validate: false) }
  after_destroy -> { idea.save(validate: false) }

  public
    def allowed?(action, user, opts = {})
      true
    end

  class << self
    public
      def allowed?(action, user, opts = {})
        true
      end

  end
end
