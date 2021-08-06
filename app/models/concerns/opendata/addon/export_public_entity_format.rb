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

      node = node.becomes_with_route
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

          row = []
          no = format("%010d", dataset.id)

          pref, city = dataset.pref_codes
          code = nil
          code = city.first if city.present?
          code = pref.first if pref.present?

          category_filenames = dataset.categories.pluck(:filename).map do |filename|
            parent = filename.index("/") ? ::File.dirname(filename) : nil
            [filename, parent]
          end

          cate1 = category_filenames.map do |filename, parent|
            st_categories1[filename] || st_categories1[parent]
          end.compact.uniq.join("\n")

          cate2 = category_filenames.map { |filename, _| st_categories2[filename] }.compact.join("\n")

          estat_category_filenames = dataset.estat_categories.pluck(:filename).map do |filename|
            parent = filename.index("/") ? ::File.dirname(filename) : nil
            [filename, parent]
          end

          cate3 = estat_category_filenames.map do |filename, parent|
            st_estat_categories1[filename] || st_estat_categories1[parent]
          end.compact.uniq.join("\n")

          cate4 = estat_category_filenames.map { |filename, _| st_estat_categories2[filename] }.compact.join("\n")

          resources = dataset.resources.to_a

          row << (code ? code.code : "")
          row << no
          row << (code ? code.prefecture : "")
          row << (code ? code.city : "")
          row << dataset.name
          row << dataset.text
          row << resources.map { |r| r.format }.uniq.join("\n")
          row << cate1
          row << cate2
          row << cate3
          row << cate4
          row << dataset.update_plan
          row << dataset.full_url
          row << dataset.label(:api_state)
          row << resources.map { |r| r.license.name }.uniq.join("\n")
          row << dataset.created.strftime("%Y-%m-%d")
          row << dataset.updated.strftime("%Y-%m-%d")
          row << resources.map { |r| (r.source_url.presence || r.name) }.uniq.join("\n")

          data << encode_sjis_csv(row)
        end
      end
    end
  end
end
