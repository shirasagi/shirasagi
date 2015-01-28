class Job::Model
  extend SS::Translation
  include SS::Document
  include SS::Task::Model
  include SS::Reference::User
  #include SS::Reference::Site

  field :pool, type: String
  field :class_name, type: String
  field :args, type: Array
  field :priority, type: Integer, default: -> { Time.now.to_i }
  field :at, type: Integer, default: -> { Time.now.to_i }

  belongs_to :site, class_name: "SS::Site"

  before_validation :set_name

  scope :site, ->(site) { where(site_id: (site.nil? ? nil : site.id)) }

  class << self
    public
      def enqueue(entity)
        model = Job::Model.new(entity)
        yield model if block_given?
        model.save!
        model
      end

      def dequeue(name)
        criteria = Job::Model.where(pool: name, started: nil)
        criteria = criteria.lte(at: Time.now)
        criteria = criteria.asc(:priority)
        criteria.find_and_modify({ '$set' => { started: Time.now }}, new: true)
      end
  end

  private
    def set_name
      self.name = 'job:model' if self.name.blank?
    end
end
