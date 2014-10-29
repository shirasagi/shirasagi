class Workflow::Extensions::WorkflowApprovers < Array
  def mongoize
    self.to_a
  end

  class << self
    def demongoize(object)
      ret = ""
      object.map { |d| ret << (d.values).join(",") + "\r\n" } if object.present?
      ret
    end

    def mongoize(object)
      case object
      when self.class then object.mongoize
      when String then
        set = []
        object.split(/\r\n|\n/).map do |d|
          begin
            h = Hash[[:level, :user_id, :state, :comment].zip(d.split(","))]
            h[:level] = h[:level].to_i
            h[:user_id] = h[:user_id].to_i
            h[:comment] = "" if h[:comment].blank?
            set << h
          rescue => e
            nil
          end
        end
#        set.mongoize

        if set.present?
          self.new(set).mongoize
        else
          self.new([]).mongoize
        end

      else
        object
      end
    end

    def evolve(object)
      case object
      when self.class then object.mongoize
      else
        object
      end
    end
  end
end
