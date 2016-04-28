require "csv"
 
module Article::Addon
  module Import
 
  extend ActiveSupport::Concern
  extend SS::Addon
 
  included do
    attr_accessor :in_file, :imported
    permit_params :in_file
  end

  module ClassMethods
    public
      def to_csv
        csv = CSV.generate do |data|
          data << %w(id name file_name layout order keywords description summary_html html categories event_name event_dates contact_state contact_group contact_charge contact_tel contact_fax contact_email released release_date close_date groups permission_level)
          criteria.each do |item|
            line = []
            line << item.id
            line << item.name
            line << item.filename
            line << Cms::Layout.where(_id: item.layout_id).map(&:name).first
            line << item.order
            line << item.keywords
            line << item.description
            line << item.summary_html
            line << item.html
            line << get_category_tree(item)
            line << item.event_name
            line << item.event_dates
            if item.contact_state == "show"
              line << I18n.t("views.options.state.show")
            else
              line << I18n.t("views.options.state.hide")
            end
            line << item.contact_group.name
            line << item.contact_charge
            line << item.contact_tel
            line << item.contact_fax
            line << item.contact_email
            line << item.released
            line << item.release_date
            line << item.close_date
            line << item.groups.map(&:name).join("\n")
            line << item.permission_level
            data << line
          end
        end
      end
     
    private
      def get_category_tree(item)
        id_list = item.send(:categories).pluck(:_id)
     
        categories = []
        id_list.each do |id|
          name_list = []
          filename_str = []
          filename_array = Cms::Node.where(_id: id).map(&:filename).first.split(/\//)
          filename_array.each do |filename|
            filename_str << filename
            name_list << Cms::Node.where(filename: filename_str.join("/")).map(&:name).first
          end
          categories << name_list.join("/")
        end
        return categories.join("\n")
     
      end
  end

  public

    def import
      @imported = 0
      validate_import 
      return false unless errors.empty?  

      table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, i|
        update_row(row, i + 2)
      end
      return errors.empty?
    end

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
     
    def validate_import
      return errors.add :in_file, :blank if in_file.blank? 
        
      fname = in_file.original_filename 
      return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~ /^\.csv$/i
      begin
        table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
        in_file.rewind
      rescue => e
        errors.add :in_file, :invalid_file_type
      end
    end
     
    def update_row(row, index)
      e = I18n.t("errors.messages.invalid")

      id = row["id"].to_s.strip
      name = row["name"].to_s.strip
      file_name = row["file_name"].to_s.strip
      if row["layout"].to_s.strip != ""
        layout_id = Cms::Layout.where(name: row["layout"].to_s.strip).map(&:_id).first
        if layout_id.blank?
          self.errors.add :base, "#{index}: layout#{e}"
          return nil
        end
      else
        layout_id = nil
      end
      order = row["order"].to_s
      keywords = row["keywords"].to_s.strip
      description = row["description"].to_s.strip
      summary_html = row["summary_html"].to_s.strip
      html = row["html"].to_s.strip
      categories = row["categories"].to_s.split(/\n/)
      event_name = row["event_name"].to_s.strip
      event_dates = row["event_dates"].to_s.strip
      if row["contact_state"].to_s.strip == I18n.t("views.options.state.show")
        contact_state = "show"
      elsif row["contact_state"].to_s.strip == I18n.t("views.options.state.hide")
        contact_state = "hide"
      else
        self.errors.add :base, "#{index}: contact_state#{e}"
        return nil
      end 
      contact_group = row["contact_group"].to_s.strip
      contact_charge = row["contact_charge"].to_s.strip
      contact_tel = row["contact_tel"].to_s.strip
      contact_fax = row["contact_fax"].to_s.strip
      contact_email = row["contact_email"].to_s.strip
      released = row["released"].to_s.strip
      release_date = row["release_date"].to_s.strip
      close_date = row["close_date"].to_s.strip
      groups = row["groups"].to_s.split(/\n/)
      permission_level = row["permission_level"].to_s
 
      if id.present?
        item = self.class.where(id: id).first
   
        if item.blank?
          self.errors.add :base, "#{index}: #{t(:id)}#{e}"
          return nil
        end
      else
        self.errors.add :base, "#{index}: #{t(:id)}#{e}"
        return nil
      end
   
      unless add_order(item, order)
        self.errors.add :base, "#{index}: order#{e}"
        return nil
      end

      unless add_category_ids(item, categories)
        self.errors.add :base, "#{index}: categories#{e}"
        return nil
      end

      unless add_contact_group_id(item, contact_group)
        self.errors.add :base, "#{index}: contact_group#{e}"
        return nil
      end

      unless add_group_ids(item, groups)
        self.errors.add :base, "#{index}: groups#{e}"
        return nil
      end

      unless add_permission_level(item, permission_level)
        self.errors.add :base, "#{index}: permission_level#{e}"
        return nil
      end

      item.name = name
      item.filename = file_name
      item.layout_id = layout_id
      item.keywords = keywords
      item.description = description
      item.summary_html = summary_html
      item.html = html
      item.event_name = event_name
      item.event_dates = event_dates
      item.contact_state = contact_state
      item.contact_charge = contact_charge
      item.contact_tel = contact_tel
      item.contact_fax = contact_fax
      item.contact_email = contact_email
      item.released = released
      item.release_date = release_date
      item.close_date = close_date
      item.updated = Time.now

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end

    def add_category_ids(item, categories)
      ids = []
      e = I18n.t("errors.messages.invalid")

      categories.each do |category|
        filename = ""
        depth = 1
        name_array = category.strip.split(/\//)
        name_array.each do |name|
          filename_array = Cms::Node.where(name: name, filename: /^#{filename}/, depth: depth).map(&:filename)

          unless filename_array.length == 1
            return false
          end

          filename = filename_array[0]

          depth = depth + 1
        end
        id = Cms::Node.where(filename: filename).map(&:_id).first

        if id.nil?
          return false
        end
        if ids.include?(id)
          return false
        end

        ids << id
      end
      item.category_ids = ids 
      return true

    end

    def add_contact_group_id(item, contact_group)
      id = SS::Group.where(name: contact_group).map(&:_id).first

      if id.nil?
        return false
      end

      item.contact_group_id = id
      return true
    end

    def add_group_ids(item, groups)
      ids = []

      groups.each do |group|
        id = SS::Group.where(name: group.strip).map(&:_id).first

        if id.nil?
          return false
        end
        if ids.include?(id)
          return false
        end

        ids << id
      end

      item.group_ids = ids
      return true
    end

    def add_order(item, order)
      unless integer_string?(order)
        return false
      end

      item.order = order.to_i
    end

    def add_permission_level(item, permission_level)
      unless integer_string?(permission_level)
        return false
      end

      unless permission_level.to_i >= 1 && permission_level.to_i <=3 
        return false
      end

      item.permission_level = permission_level.to_i
    end

    def integer_string?(str)
      Integer(str)
      return true
    rescue ArgumentError
      return false
    end

    def set_errors(item, index)
      error = ""
      item.errors.each do |n, e|
        error += "#{item.class.t(n)}#{e} "
      end
      self.errors.add :base, "#{index}: #{error}"
    end
  end
end 
