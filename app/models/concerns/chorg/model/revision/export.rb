module Chorg::Model::Revision
  module Export
    extend ActiveSupport::Concern

    included do
      cattr_accessor :changeset_class
      class_variable_set(:@@changeset_class, Chorg::Changeset)

      attr_accessor :in_revision_csv_file

      permit_params :in_revision_csv_file

      validate if: -> { in_revision_csv_file.present? } do
        I18n.with_locale(I18n.default_locale) { validate_in_revision_csv_file }
      end
      before_save do
        I18n.with_locale(I18n.default_locale) { import_revision_csv_file }
      end
    end

    def changesets_to_csv
      I18n.with_locale(I18n.default_locale) do
        CSV.generate do |data|
          data << %w(
            id type source destination order
            contact_tel contact_fax contact_email contact_link_url contact_link_name
            ldap_dn
          ).map { |k| I18n.t("chorg.import.changeset.#{k}") }

          export_sets = changesets.sort(&changeset_class.method(:comparer))
          export_sets.each do |item|
            case item.type
            when changeset_class::TYPE_UNIFY

              # N sources, 1 destination
              destination = item.destinations.to_a.first || {}
              item.sources.to_a.each do |source|
                data << changeset_to_csv_line(item, source, destination)
              end
            when changeset_class::TYPE_DIVISION

              # 1 source, N destinations
              source = item.sources.to_a.first || {}
              item.destinations.to_a.each do |destination|
                data << changeset_to_csv_line(item, source, destination)
              end
            else

              # 1 source, 1 destination
              source = item.sources.to_a.first || {}
              destination = item.destinations.to_a.first || {}
              data << changeset_to_csv_line(item, source, destination)
            end
          end
        end
      end
    end

    def changesets_sample_csv
      I18n.with_locale(I18n.default_locale) do
        CSV.generate do |data|
          data << %w(
            id type source destination order
            contact_tel contact_fax contact_email contact_link_url contact_link_name
            ldap_dn
          ).map { |k| I18n.t("chorg.import.changeset.#{k}") }
          SS.config.chorg.changeset_sample_csv.each { |line| data << line }
        end
      end
    end

    private

    def changeset_to_csv_line(changeset, source, destination)
      line = []
      line << changeset.id
      line << I18n.t("chorg.options.changeset_type.#{changeset.type}")
      line << source["name"]
      line << destination["name"]
      line << destination["order"]
      line << destination["contact_tel"]
      line << destination["contact_fax"]
      line << destination["contact_email"]
      line << destination["contact_link_url"]
      line << destination["contact_link_name"]
      line << destination["ldap_dn"]
      line
    end

    def csv_line_to_changeset_attributes(line)
      @_type_labels ||= I18n.t("chorg.options.changeset_type").map { |k, v| [v, k] }.to_h

      source_name = line[I18n.t("chorg.import.changeset.source")].to_s.strip

      attr = {}
      attr["id"] = line[I18n.t("chorg.import.changeset.id")].to_s.strip.to_i
      attr["type"] = @_type_labels[line[I18n.t("chorg.import.changeset.type")]].to_s.strip
      attr["source"] = {
        "name" =>source_name
      }
      attr["destination"] = {
        "name" => line[I18n.t("chorg.import.changeset.destination")].to_s.strip,
        "order" => line[I18n.t("chorg.import.changeset.order")].to_s.strip,
        "contact_tel" => line[I18n.t("chorg.import.changeset.contact_tel")].to_s.strip,
        "contact_fax" => line[I18n.t("chorg.import.changeset.contact_fax")].to_s.strip,
        "contact_email" => line[I18n.t("chorg.import.changeset.contact_email")].to_s.strip,
        "contact_link_url" => line[I18n.t("chorg.import.changeset.contact_link_url")].to_s.strip,
        "contact_link_name" => line[I18n.t("chorg.import.changeset.contact_link_name")].to_s.strip,
        "ldap_dn" => line[I18n.t("chorg.import.changeset.ldap_dn")].to_s.strip
      }

      if source_name.present?
        group = SS::Group.where(name: source_name).first
        attr["source"]["id"] = group.id if group
      end

      attr
    end

    def validate_in_revision_csv_file
      @add_sets = []
      @move_sets = []
      @unify_sets = {}
      @division_sets = {}
      @delete_sets = []

      if ::File.extname(in_revision_csv_file.original_filename).try(:downcase) != ".csv"
        errors.add :base, :invalid_csv
        return
      end
      if !SS::Csv.valid_csv?(in_revision_csv_file, headers: true)
        errors.add :base, :malformed_csv
        return
      end

      in_revision_csv_file.rewind
      SS::Csv.foreach_row(in_revision_csv_file, headers: true) do |line, idx|
        attr = csv_line_to_changeset_attributes(line)
        id = attr["id"]
        type = attr["type"]
        source = attr["source"]
        destination = attr["destination"]

        case type
        when changeset_class::TYPE_ADD

          # 0 source, 1 destination
          changeset = changeset_class.new
          changeset.type = type
          changeset.cur_revision = self
          changeset.destinations = [destination]
          @add_sets << [changeset, idx + 2]

        when changeset_class::TYPE_MOVE

          # 1 source, 1 destination
          changeset = changeset_class.new
          changeset.type = type
          changeset.cur_revision = self
          changeset.sources = [source]
          changeset.destinations = [destination]
          @move_sets << [changeset, idx + 2]

        when changeset_class::TYPE_UNIFY

          # N sources, 1 destination
          key = [id, destination["name"]]
          if @unify_sets[key]
            changeset, before_idx = @unify_sets[key]
            changeset.sources << source
            @unify_sets[key] = [changeset, before_idx + [idx + 2]]
          else
            changeset= changeset_class.new
            changeset.type = type
            changeset.cur_revision = self
            changeset.sources = [source]
            changeset.destinations = [destination]
            @unify_sets[key] = [changeset, [idx + 2]]
          end

        when changeset_class::TYPE_DIVISION

          # 1 source, N destinations
          key = [id, source["name"]]
          if @division_sets[key]
            changeset, before_idx = @division_sets[key]
            changeset.destinations << destination
            @division_sets[key] = [changeset, before_idx + [idx + 2]]
          else
            changeset = changeset_class.new
            changeset.type = type
            changeset.cur_revision = self
            changeset.sources = [source]
            changeset.destinations = [destination]
            @division_sets[key] = [changeset, [idx + 2]]
          end

        when changeset_class::TYPE_DELETE

          # 1 source, 0 destination
          changeset = changeset_class.new
          changeset.type = type
          changeset.cur_revision = self
          changeset.sources = [source]
          @delete_sets << [changeset, idx + 2]

        end
      end

      @add_sets.each do |changeset, idx|
        next if changeset.valid?
        changeset.errors.full_messages.each do |e|
          errors.add :base, "#{idx} (#{I18n.t("chorg.options.changeset_type.#{changeset.type}")}) : #{e}"
        end
      end
      @move_sets.each do |changeset, idx|
        next if changeset.valid?
        changeset.errors.full_messages.each do |e|
          errors.add :base, "#{idx} (#{I18n.t("chorg.options.changeset_type.#{changeset.type}")}) : #{e}"
        end
      end
      @unify_sets.each do |key, changesets|
        changeset, idx = changesets
        next if changeset.valid?
        changeset.errors.full_messages.each do |e|
          errors.add :base, "#{idx.join(",")} (#{I18n.t("chorg.options.changeset_type.#{changeset.type}")}) : #{e}"
        end
      end
      @division_sets.each do |key, changesets|
        changeset, idx = changesets
        next if changeset.valid?
        changeset.errors.full_messages.each do |e|
          errors.add :base, "#{idx.join(",")} (#{I18n.t("chorg.options.changeset_type.#{changeset.type}")}) : #{e}"
        end
      end
      @delete_sets.each do |changeset, idx|
        next if changeset.valid?
        changeset.errors.full_messages.each do |e|
          errors.add :base, "#{idx} (#{I18n.t("chorg.options.changeset_type.#{changeset.type}")}) : #{e}"
        end
      end
    end

    def import_revision_csv_file
      return if in_revision_csv_file.blank?
      changesets.destroy_all

      if @add_sets
        @add_sets.each do |changeset, idx|
          changeset.revision_id = self.id
          changeset.save!
        end
      end

      if @move_sets
        @move_sets.each do |changeset, idx|
          changeset.revision_id = self.id
          changeset.save!
        end
      end

      if @unify_sets
        @unify_sets.each do |key, changesets|
          changeset, idx = changesets
          changeset.revision_id = self.id
          changeset.save!
        end
      end

      if @division_sets
        @division_sets.each do |key, changesets|
          changeset, idx = changesets
          changeset.revision_id = self.id
          changeset.save!
        end
      end

      if @delete_sets
        @delete_sets.each do |changeset, idx|
          changeset.revision_id = self.id
          changeset.save!
        end
      end
    end
  end
end
