module Tasks
  class SS
    class Models
      class << self
        def call
          @models = {}
          @fields = {}
          @errors = []

          puts "Analysing..."

          # load all models
          ::Rails.application.eager_load!

          Mongoid.models.sort_by(&:to_s).each do |model|
            next if model.to_s =~ /^Mongoid::/
            puts "- #{model}"

            coll = model.collection_name
            @models[coll] ||= nil
            @fields[coll] ||= {}

            if !@models[coll]
              coll_t = I18n.t("mongoid.models.#{coll.to_s.singularize.sub('_', '/')}", raise: true) rescue nil
              coll_t ||= I18n.t("mongoid.models.#{model.to_s.underscore}", raise: true) rescue nil
              @errors << [model.to_s.underscore] unless coll_t
              @models[coll] = coll_t
            end

            model.fields.sort.each do |name, field|
              @fields[coll][name] ||= {}
              @fields[coll][name][:type] ||= field.type.to_s

              next if @fields[coll][name][:name]

              name_t = (name == "_id") ? 'ID' : model.t(name) rescue nil
              name_t = nil if name == name_t
              @errors << ["#{model.to_s.underscore}.#{name}"] unless name_t
              @fields[coll][name][:name] = name_t
            end
          end

          puts "\n----\nStatistics"
          puts "- Models: #{@models.size}"
          puts "- Missing: #{@errors.size}"

          puts "\n----\nOutput"
          write("#{Rails.root}/tmp/models.md", markdown)
          write("#{Rails.root}/tmp/models.tsv", tsv, "w:windows-31j")
          write_pdf("#{Rails.root}/tmp/models.pdf")
        end

        private

        def output_header
          "Database Schema v#{::SS.version}" # Time.zone.now.strftime('%Y.%m.%d')
        end

        def markdown
          header = "# #{output_header}\n\n"
          header + @models.sort.map do |coll, coll_t|
            lines = []
            lines << "## " + [coll, coll_t].compact.join(' / ')
            lines << ""
            lines << "|Field|Description|Type|"
            lines << "|-----|-----------|----|"

            @fields[coll].each { |k, v| lines << "|#{k}|#{v[:name]}|#{v[:type]}|" }
            lines.join("\n")
          end.join("\n\n")
        end

        def tsv
          header = "#{output_header}\n\n"
          header + @models.sort.map do |coll, coll_t|
            lines = []
            lines << "Collection\tDescription"
            lines << "#{coll}\t#{coll_t}"
            lines << ""
            lines << "Field\tDescription\tType"

            @fields[coll].each { |k, v| lines << "#{k}\t#{v[:name]}\t#{v[:type]}" }
            lines.join("\n")
          end.join("\n\n")
        end

        def write_pdf(filename)
          require 'thinreports'
          report = Thinreports::Report.new layout: "#{Rails.root}/lib/fixtures/ss/models"

          @models.sort.map do |coll, coll_t|
            report.start_new_page

            report.list.header do |header|
              header.item(:collection_name).value(coll)
            end

            @fields[coll].each do |key, val|
              report.list.add_row do |row|
                row.item(:name).value(key)
                row.item(:type).value(val[:type])
                row.item(:description).value(val[:name])
              end
            end
          end

          puts "- #{filename}"
          report.generate(filename: filename)
        end

        def write(file, data, mode = "w")
          puts "- #{file}"
          File.open(file, mode) { |f| f.puts(data) }
        end
      end
    end
  end
end
