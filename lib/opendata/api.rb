module Opendata::Api

  public
    def check_num(num, messages)
      if num
        if integer?(num)
          if num.to_i < 0
            messages << "Must be a natural number"
          end
        else
          messages << "Invalid integer"
        end
      end

    end

    def integer?(s)
      i = Integer(s)
      check = true
    rescue
      check = false
    end

end