require "csv"

module Article::Addon::Import
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_file, :imported
    permit_params :in_file
  end

  FIELDS = %w(id name file_name layout order keywords description summary_html html categories parent_crumb_urls
              event_name event_dates contact_state contact_group contact_charge contact_tel contact_fax contact_email
              released release_date close_date groups permission_level).freeze

  module ClassMethods
    def to_csv
      CSV.generate do |data|
        data << Article::Addon::Import::FIELDS.map { |k| Article::Page.t k.to_sym }
        criteria.each { |item| data << item_to_csv(item) }
      end
    end

    private
      def item_to_csv(item)
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
        line << item.parent_crumb_urls
        line << item.event_name
        line << item.event_dates
        if item.contact_state == "show"
          line << I18n.t("views.options.state.show")
        else
          line << I18n.t("views.options.state.hide")
        end
        line << SS::Group.where(_id: item.contact_group_id).map(&:name).first
        line << item.contact_charge
        line << item.contact_tel
        line << item.contact_fax
        line << item.contact_email
        line << item.released
        line << item.release_date
        line << item.close_date
        line << item.groups.map(&:name).join("\n")
        line << item.permission_level
        line
      end

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
        categories.join("\n")
      end
  end

  def import_csv
    @imported = 0
    validate_import
    return false unless errors.empty?

    table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      update_row(row, i + 2)
    end

    errors.empty?
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

      attributes = build_attributes(row, index)
      return nil if attributes.nil?

      id = attributes.delete(:id)
      if id.present?
        item = self.class.where(id: id).first
        if item.blank?
          self.errors.add :base, "#{index}: #{t(:id)}#{e}"
          return nil
        end
      else
        item = self.new
      end

      item.attributes = attributes
      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end

    def build_attributes(row, index)
      e = I18n.t("errors.messages.invalid")
      attributes = {}

      Article::Addon::Import::FIELDS.each do |f|
        f = f.to_sym
        value = row[Article::Page.t(f)].to_s.strip

        case f
        when :file_name
          attributes[:filename] = value
        when :layout
          attributes[:layout_id] = find_layout_id(value)
          if attributes[:layout_id].blank?
            self.errors.add :base, "#{index}: layout#{e}"
            return nil
          end
        when :order, :permission_level
          attributes[f] = convert_to_integer(value)
          if attributes[f].blank?
            self.errors.add :base, "#{index}: #{f}#{e}"
            return nil
          end
        when :categories
          attributes[:category_ids] = value.split(/\n/).map { |category| find_category_id(category.strip) }.uniq
        when :contact_state
          attributes[:contact_state] = convert_contact_state(value)
          if attributes[:contact_state].blank?
            self.errors.add :base, "#{index}: contact_state#{e}"
            return nil
          end
        when :contact_group
          attributes[:contact_group_id] = SS::Group.where(name: value).first.try(:id)
          if attributes[:contact_group_id].blank?
            self.errors.add :base, "#{index}: contact_group#{e}"
            return nil
          end
        when :groups
          attributes[:group_ids] = value.split(/\n/).map { |group| SS::Group.where(name: group.strip).first.try(:id) }
        else
          attributes[f] = value
        end
      end

      attributes
    end

    def find_layout_id(layout_name)
      Cms::Layout.where(name: layout_name).first.try(:id)
    end

    def find_category_id(category)
      filename = ""
      depth = 1
      name_array = category.strip.split(/\//)
      name_array.each do |name|
        filename_array = Cms::Node.where(name: name, filename: /^#{filename}/, depth: depth).map(&:filename)

        unless filename_array.length == 1
          return false
        end

        filename = filename_array[0]

        depth += 1
      end
      Cms::Node.where(filename: filename).first.try(:id)
    end

    def convert_contact_state(contact_state)
      if contact_state == I18n.t("views.options.state.show")
        return "show"
      elsif contact_state == I18n.t("views.options.state.hide")
        return "hide"
      else
        return nil
      end
    end

    def convert_to_integer(value)
      Integer(value)
    rescue
      nil
    end

    def set_errors(item, index)
      error = ""
      item.errors.each do |n, e|
        error += "#{item.class.t(n)}#{e} "
      end
      self.errors.add :base, "#{index}: #{error}"
    end
end
