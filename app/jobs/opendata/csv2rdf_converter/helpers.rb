module Opendata::Csv2rdfConverter::Helpers
  module Context
    attr_reader :cur_site, :cur_user, :cur_node, :cur_dataset, :cur_resource
    attr_reader :item, :csv, :uri, :tmp_dir, :tmp_file

    def init_context(dataset, resource)
      @cur_site = self.site
      @cur_user = self.user
      @cur_node = self.node
      @cur_dataset = Opendata::Dataset.site(@cur_site).node(@cur_node).find(dataset)
      @cur_resource = @cur_dataset.resources.find(resource)
      @item = Opendata::Csv2rdfSetting.site(@cur_site).resource(@cur_resource).first
      @csv = @cur_resource.parse_tsv
      @uri = "#{UNF::Normalizer.normalize(@cur_resource.full_url, :nfkc)}#"
      @tmp_dir = nil
      @tmp_file = nil
    end

    def dispose_context
    end

    def create_tempfile
      ::Dir.mktmpdir do |dir|
        @tmp_dir = dir
        tmp_filename = ::File.join(dir, File.basename(@cur_resource.filename).gsub(/\..+?$/, '.ttl'))
        @tmp_file = ::File.open(tmp_filename, "a+:utf-8")

        begin
          yield @tmp_file
        ensure
          @tmp_file.close
        end

        @tmp_file = nil
      end
      @tmp_dir = nil
    end
  end

  module Common
    include Context

    def ignore_column?(column_index)
      type_setting = @item.column_types[column_index]
      type_setting["classes"].first == false
    end

    def fallback_property_name(column_index)
      name = @item.header_labels[column_index].map { |e| UNF::Normalizer.normalize(e.strip, :nfkc) }.join("_")
      name.gsub!(/\s+/, '_')
      name
    end

    def normalize_value(value, column_index)
      type_setting = @item.column_types[column_index]
      classes = type_setting["classes"]
      last_class = classes.last
      if last_class == "xsd:integer"
        if /^[-+]?[0-9,]+$/ =~ value
          "\"#{value.delete(",")}\"^^#{last_class}"
        else
          "\"#{value.delete(",")}\""
        end
      elsif last_class == "xsd:decimal"
        if /^[-+]?[0-9,]+\.[0-9]+$/ =~ value
          "\"#{value.delete(",")}\"^^#{last_class}"
        else
          "\"#{value.delete(",")}\""
        end
      elsif value.start_with?("http:", "https:")
        "<#{value}>"
      else
        "\"#{value}\""
      end
    end
  end

  module Header
    include Context
    include Common

    def put_header
      dc, cc = put_prefix

      put_fileinfo(dc, cc)

      put_property
    end

    def put_prefix
      @tmp_file.puts "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
      @tmp_file.puts "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ."
      dc = nil
      cc = nil
      Rdf::Vocab.each do |vocab|
        @tmp_file.puts "@prefix #{vocab.prefix}: <#{vocab.uri}> ."
        if vocab.uri == "http://purl.org/dc/terms/"
          dc = vocab.prefix
        end
        if vocab.uri == "http://creativecommons.org/ns#"
          cc = vocab.prefix
        end
      end
      if dc.blank?
        @tmp_file.puts "@prefix dc: <http://purl.org/dc/terms/> ."
        dc = "dc"
      end
      if cc.blank?
        @tmp_file.puts "@prefix cc: <http://creativecommons.org/ns#> ."
        cc = "cc"
      end
      @tmp_file.puts "@prefix endemic_vocab: <#{@uri}> ."
      @tmp_file.puts

      [dc, cc]
    end

    def put_fileinfo(dc, cc)
      @tmp_file.puts "## ファイル情報 ####"
      @tmp_file.puts "<#{@uri}>"
      @tmp_file.puts "  rdfs:label \"#{@cur_dataset.name}\"@ja ;" if @cur_dataset.name.present?
      @tmp_file.puts "  rdfs:comment \"#{@cur_dataset.text}\"@ja ;" if @cur_dataset.text.present?
      @tmp_file.puts "  #{cc}:license \"#{@cur_resource.license.name}\" ;" if @cur_resource.license.present?
      @tmp_file.puts "  #{dc}:modified \"#{@cur_resource.updated.strftime("%Y-%m-%d")}\"" \
                      + "^^<http://www.w3.org/2001/XMLSchema#date> ."
      @tmp_file.puts
    end

    def put_property
      @tmp_file.puts "## 固有プロパティ ####"
      @item.header_labels.each_with_index do |column_labels, column_index|
        next if ignore_column?(column_index)

        type_setting = @item.column_types[column_index]
        properties = type_setting["properties"]
        if properties.blank?
          @tmp_file.puts "endemic_vocab:#{fallback_property_name(column_index)} a rdf:Property ;"
          column_labels.each do |column_label|
            next if column_label.blank?
            @tmp_file.puts "  rdfs:label \"#{column_label}\"@ja ;"
          end
          @tmp_file.puts "  rdfs:range #{type_setting["classes"].first} ."
        end
      end
      @tmp_file.puts
    end
  end

  module Footer
    def put_footer
    end
  end

  module TtlResource
    # see: http://wiki.suikawiki.org/n/application%2Fx-turtle
    TURTLE_CONTENT_TYPE = "text/turtle".freeze

    def save_and_send_ttl
      params = {}
      params[:name] = @cur_resource.name.gsub(/\..+?$/, '.ttl')
      # params[:filename] = @cur_resource.filename.gsub(/\..+?$/, '.ttl')
      params[:text] = @cur_resource.text
      params[:format] = "TTL"
      params[:license_id] = @cur_resource.license_id
      params[:in_file] = Opendata::Csv2rdfConverter::FakeUploadedFile.new(@tmp_file, TURTLE_CONTENT_TYPE)
      params[:cur_host] = @cur_host if Opendata::Resource.respond_to?(:cur_host)
      params[:cur_user] = @cur_user if @cur_user.present? && Opendata::Resource.respond_to?(:cur_user)
      params[:cur_node] = @cur_node if Opendata::Resource.respond_to?(:cur_node)

      filename = @cur_resource.filename.gsub(/\..+?$/, '.ttl')

      res = @cur_dataset.resources.where(filename: filename).first
      if res.present?
        res.attributes = params
        res.update
      else
        res = @cur_dataset.resources.create(params)
      end
      params[:in_file].close
      res
    end
  end
end
