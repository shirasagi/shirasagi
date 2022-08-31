require "csv"

module Gws::Addon::Import
  module CustomGroup
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported

      permit_params :in_file
    end

    module ClassMethods
      def csv_headers
        %w(id name order member_group_ids member_ids)
      end

      def to_csv
        groups = SS::Group.active.pluck(:_id, :name).uniq.to_h
        users = SS::User.active.pluck(:_id, :uid).uniq.to_h
        I18n.with_locale(I18n.default_locale) do
          CSV.generate do |data|
            data << csv_headers.map { |k| t k }
            criteria.each do |item|
              line = []
              line << item.id
              line << item.name
              line << item.order
              line << item.member_group_ids.map { |m| groups[m] }.join("\n")
              line << item.member_ids.map { |m| users[m] }.join("\n")
              data << line
            end
          end
        end
      end
    end

    def import
      @imported = 0

      validate_import
      return false unless errors.empty?

      table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
      @groups = Gws::Group.site(cur_site).pluck(:name, :_id).uniq.to_h
      @users = Gws::User.site(cur_site).pluck(:uid, :_id).uniq.to_h

      I18n.with_locale(I18n.default_locale) do
        table.each_with_index do |row, i|
          update_row(row, i + 2)
        end
      end
      return errors.empty?
    end

    private

    def validate_import
      return errors.add :in_file, :blank if in_file.blank?
      return errors.add :cur_site, :blank if cur_site.blank?

      fname = in_file.original_filename
      unless /^\.csv$/i.match?(::File.extname(fname))
        errors.add :in_file, :invalid_file_type
        return
      end

      begin
        CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
        in_file.rewind
      rescue => e
        errors.add :in_file, :invalid_file_type
      end
    end

    def update_row(row, index)
      id = row[t("id")].to_s.strip
      name = row[t("name")].to_s.strip
      order = row[t("order")].to_s.strip
      member_group_ids = row[t("member_group_ids")].to_s.split(/\n/).map(&:strip)
      member_ids = row[t("member_ids")].to_s.split(/\n/).map(&:strip)

      if id.present?
        item = self.class.unscoped.site(cur_site).where(id: id).first
        if item.blank?
          self.errors.add :base, :not_found, line_no: index, id: id
          return nil
        end

        if name.blank?
          item.disable
          @imported += 1
          return nil
        end
      else
        item = self.class.new
      end

      item.name = name
      item.order = order

      item.member_group_ids = member_group_ids.map { |m| get_group_id(m, index) }
      item.member_ids = member_ids.map { |m| get_user_id(m, index) }
      item.site_id = cur_site.id

      return nil if errors.present?

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end

    def get_group_id(name, index)
      if @groups.key?(name)
        @groups[name]
      else
        self.errors.add :base, :not_found_group, line_no: index, name: name
        nil
      end
    end

    def get_user_id(uid, index)
      if @users.key?(uid)
        @users[uid]
      else
        self.errors.add :base, :not_found_user, line_no: index, uid: uid
        nil
      end
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
