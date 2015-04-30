class Opendata::Csv2rdfConverter::Job
  include ::Job::Worker
  include Opendata::Csv2rdfConverter::Helpers::Context
  include Opendata::Csv2rdfConverter::Helpers::Common
  include Opendata::Csv2rdfConverter::Helpers::Header
  include Opendata::Csv2rdfConverter::Helpers::Footer
  include Opendata::Csv2rdfConverter::Helpers::TtlResource

  public
    def call(host, user, cid, dataset, resource)
      init_context(host, user, cid, dataset, resource)
      create_tempfile do
        put_header
        put_linkdata
        put_footer

        # @tmp_file.flush
        @tmp_file.close
        save_and_send_ttl
      end
      dispose_context
      Rails.logger.info(I18n.t("opendata.messages.build_rdf_success"))
      nil
    rescue => e
      Rails.logger.error("#{I18n.t("opendata.errors.messages.build_rdf_failed")}\n" \
        "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise
    end

  private
    def put_linkdata
      @tmp_file.puts "## リンクデータ ####"
      each_data_row do |row, index|
        tree = build_tree(row)
        next if tree.blank?

        @tmp_file.puts "<#{@uri}#{index}>"
        write_index(@tmp_file, 0)
        @tmp_file.puts "a #{@item.rdf_class.vocab.prefix}:#{@item.rdf_class.name} ;"
        write_tree(@tmp_file, tree)
        @tmp_file.puts
      end
    end

    def each_data_row
      @csv[@item.header_rows..@csv.length].each_with_index do |row, index|
        yield row, index + 1
      end
    end

    def build_tree(row)
      root = {}
      row.each_with_index do |val, column_index|
        next if val.blank? || ignore_column?(column_index)
        type_setting = @item.column_types[column_index]
        properties = type_setting["properties"]
        properties = ["endemic_vocab:#{fallback_property_name(column_index)}"] if properties.blank?

        subtree = root
        properties[0..-2].each_with_index do |name, i|
          subtree[name] ||= {}
          subtree[name][:class] ||= type_setting["classes"][i]
          subtree[name][:tree] ||= {}
          subtree = subtree[name][:tree]
        end

        subtree[properties.last] = normalize_value(val, column_index)
      end
      root
    end

    def write_index(f, depth)
      f.write "  " * (depth + 1)
    end

    def write_tree(f, tree, depth = 0)
      tree.each_with_index do |item, index|
        key, value = item
        write_value(f, key, value, depth, index + 1 == tree.size)
      end
    end

    def write_value(f, key, value, depth, is_last)
      write_index(f, depth)
      delim = is_last ? (depth == 0 ? " ." : "") : " ;"
      if value.is_a?(Hash)
        f.puts "#{key} ["
        write_index(f, depth + 1)
        f.puts "a #{value[:class]} ;"
        write_tree(f, value[:tree], depth + 1)
        write_index(f, depth)
        f.puts "]#{delim}"
      else
        f.puts "#{key} #{value}#{delim}"
      end
    end
end
