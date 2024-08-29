module Opendata::Addon::ExportPublicEntityFormat
  extend SS::Addon
  extend ActiveSupport::Concern

  module ClassMethods
    def public_entity_csv(node)
      csv = []
      public_entity_enum_csv(node).each do |data|
        csv << data
      end
      csv.join
    end

    def public_entity_enum_csv(node)
      criteria = self.node(node)
      dataset_ids = criteria.pluck(:id)

      class << self
        def encode_sjis_csv(row)
          row.to_csv.encode("SJIS", invalid: :replace, undef: :replace)
        end

        def name_hier(category)
          names = []
          names << category.name
          while category.parent.present?
            category = category.parent
            names << category.name
          end
          names.reverse.join('/')
        end
      end

      st_categories = node.st_categories.presence || node.default_st_categories
      st_categories = st_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten

      st_estat_categories = node.st_estat_categories.presence || node.default_st_estat_categories
      st_estat_categories = st_estat_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten

      st_categories1 = {}
      st_categories2 = {}
      st_categories.each do |cate|
        st_categories1[cate.filename] = cate.name
        cate.children.and_public.sort(order: 1).each do |child|
          st_categories2[child.filename] = child.name
        end
      end

      st_estat_categories1 = {}
      st_estat_categories2 = {}
      st_estat_categories.each do |cate|
        st_estat_categories1[cate.filename] = cate.name
        cate.children.and_public.sort(order: 1).each do |child|
          st_estat_categories2[child.filename] = child.name
        end
      end

      Enumerator.new do |data|
        data << encode_sjis_csv(I18n.t("opendata.public_entity.headers"))
        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil
          next unless dataset

          no = dataset.metadata_dataset_id.presence || format("%010d", dataset.id)

          category_filenames = dataset.categories.pluck(:filename).map do |filename|
            parent = filename.index("/") ? ::File.dirname(filename) : nil
            [filename, parent]
          end

          cate1 = category_filenames.filter_map do |filename, parent|
            st_categories1[filename] || st_categories1[parent]
          end.uniq.join("\n")

          cate2 = category_filenames.filter_map { |filename, _| st_categories2[filename] }.join("\n")

          estat_category_filenames = dataset.estat_categories.pluck(:filename).map do |filename|
            parent = filename.index("/") ? ::File.dirname(filename) : nil
            [filename, parent]
          end

          cate3 = estat_category_filenames.filter_map do |filename, parent|
            st_estat_categories1[filename] || st_estat_categories1[parent]
          end.uniq.join("\n")

          cate4 = estat_category_filenames.filter_map { |filename, _| st_estat_categories2[filename] }.join("\n")

          dataset.resources.each do |resource|
            row = []
            row << no
            row << dataset.metadata_japanese_local_goverment_code
            row << dataset.metadata_local_goverment_name
            row << dataset.name
            row << nil
            row << dataset.text
            row << dataset.metadata_dataset_keyword.to_s.tr(',', ';')
            row << cate3
            row << nil
            row << dataset.created.strftime("%Y-%m-%d")
            row << dataset.updated.strftime("%Y-%m-%d")
            row << nil
            row << I18n.locale
            row << dataset.full_url
            row << dataset.update_plan
            row << dataset.metadata_dataset_follow_standards
            row << dataset.metadata_dataset_related_document
            row << nil
            row << dataset.areas.pluck(:name).join("\n")
            row << dataset.metadata_dataset_target_period
            row << dataset.metadata_dataset_contact_name
            row << dataset.metadata_dataset_contact_email
            row << dataset.metadata_dataset_contact_tel
            row << dataset.metadata_dataset_contact_ext
            row << dataset.metadata_dataset_contact_form_url
            row << dataset.metadata_dataset_contact_remark
            row << dataset.metadata_dataset_remark
            row << resource.name
            row << resource.metadata_file_access_url
            row << resource.metadata_file_download_url
            row << resource.format
            row << resource.license.try(:name)
            row << '配信中'
            row << (resource.metadata_imported_attributes['ファイル_サイズ'].presence || resource.file.try(:size))
            row << resource.created.strftime("%Y-%m-%d")
            row << resource.updated.strftime("%Y-%m-%d")
            row << resource.metadata_file_terms_of_service
            row << resource.metadata_file_related_document
            row << I18n.locale
            row << resource.metadata_file_follow_standards
            row << dataset.label(:api_state)

            data << encode_sjis_csv(row)
          end
        end
      end
    end
  end
end
