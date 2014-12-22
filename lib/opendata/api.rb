module Opendata::Api

  class << self
    public
    def package_list_param_check?(limit, offset)

      check = false
      limit_message = []
      offset_message = []

      if !limit.nil?
        if integer?(limit)
          if limit.to_i < 0
            limit_message << "Must be a natural number"
          end
        else
          limit_message << "Invalid integer"
        end
      end

      if !offset.nil?
        if integer?(offset)
          if offset.to_i < 0
            offset_message << "Must be a natural number"
          end
        else
          offset_message << "Invalid integer"
        end
      end

      messages = {}
      messages[:limit] = limit_message if !limit_message.empty?
      messages[:offset] = offset_message if !offset_message.empty?

      check_count = limit_message.size + offset_message.size
      check = true if check_count == 0

      return check, messages
    end

    def package_show_param_check?(id)

      check = false
      id_message = []
      id_message << "Missing value" if id.blank?

      messages = {}
      messages[:name_or_id] = id_message if !id_message.empty?

      check_count = id_message.size
      check = true if check_count == 0

      return check, messages
    end

    def group_list_param_check?(sort)

      check = false
      sort_message = []
      sort_values = ["name", "packages"]

      sort_message << "Cannot sort by field `#{sort}`" if !sort_values.include?(sort)

      messages = {}
      messages[:sort] = sort_message if !sort_message.empty?

      check_count = sort_message.size
      check = true if check_count == 0

      return check, messages
    end

    def group_show_param_check?(id)

      check = false
      id_message = []
      id_message << "Missing value" if id.blank?

      messages = {}
      messages[:name_or_id] = id_message if !id_message.empty?

      check_count = id_message.size
      check = true if check_count == 0

      return check, messages
    end

    def integer?(s)
      i = Integer(s)
      check = true
    rescue
      check = false
    end
  end

end