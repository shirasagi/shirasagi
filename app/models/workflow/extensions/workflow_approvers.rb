class Workflow::Extensions::WorkflowApprovers < Array
  def mongoize
    self.to_a
  end

  class << self
    def demongoize(object)
      if object.present?
        Workflow::Extensions::WorkflowApprovers.new(normalize(object))
      else
        Workflow::Extensions::WorkflowApprovers.new
      end
    end

    def mongoize(object)
      case object
      when self.class
        object.mongoize
      when Array
        Workflow::Extensions::WorkflowApprovers.new(normalize(object)).mongoize
      else
        object
      end
    end

    def evolve(object)
      case object
      when self.class
        object.mongoize
      else
        object
      end
    end

    private

    def normalize(array)
      ret = array.map do |hash|
        if hash.kind_of?(String)
          convert_from_string(hash)
        elsif hash.respond_to?(:symbolize_keys)
          hash.symbolize_keys
        else
          nil
        end
      end
      ret.compact!
      ret.each do |hash|
        hash[:level] = hash[:level].to_i if hash[:level].present?
        hash[:user_id] = hash[:user_id].to_i if hash[:user_id].present?
        hash[:editable] = hash[:editable].to_i if hash[:editable].present?
        hash[:alternatable] = hash[:alternatable].to_i if hash[:alternatable].present?
        hash[:comment] = "" if hash[:comment].blank?
        hash[:file_ids] = Array(hash[:file_ids]).flatten.select(&:numeric?).map(&:to_i) if hash[:file_ids].present?
      end
      ret.to_a.uniq
    end

    def convert_from_string(text)
      return nil if text.blank?
      begin
        Hash[[:level, :user_id, :editable, :state, :comment].zip(text.split(",").map(&:strip))]
      rescue
        nil
      end
    end
  end
end
