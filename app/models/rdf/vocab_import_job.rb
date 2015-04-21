class Rdf::VocabImportJob
  include Job::Worker
  include Rdf::Builders::Traversable

  public
    def call(host, prefix, file_or_id, owner = Rdf::Vocab::OWNER_USER, order = nil)
      begin
        @cur_site = SS::Site.find_by(host: host)
        @prefix = prefix
        if file_or_id.is_a?(Numeric)
          @temp_file = SS::TempFile.where(_id: file_or_id).first
          @filename = @temp_file.path
          @format = format_of(@temp_file.filename)
        else
          @filename = file_or_id.try(:path) || file_or_id.to_s
          @format = format_of(@filename)
        end
        @graph = RDF::Graph.load(@filename, format: @format)
        @owner = owner
        @order = order
        @vocabs = []
        @pending_classes = []
        @pending_prop_attributes = []
        @pending_class_attributes = []
        @vocab_count = 0
        @class_count = 0
        @property_count = 0

        load_and_create_vocab
        @vocabs.each do |vocab|
          load_and_create_objects(vocab)
        end

        do_process_pending_classes
        do_process_pending_prop_attributes
        do_process_pending_class_attributes

        Rails.logger.info("imported from #{@filename}: vocab count=#{@vocab_count}, class count=#{@class_count}, " \
          "property count=#{@property_count}")
      ensure
        @temp_file.delete if @temp_file
      end
    end

  private
    def format_of(file)
      case File.extname(file).downcase
      when ".ttl" then
        :ttl
      when ".xml", ".rdf" then
        :rdfxml
      else
        :ttl
      end
    end

    def load_and_create_vocab
      ontology_subject = @graph.each.first.try(:subject)
      raise Rdf::VocabImportJobError, I18n.t("rdf.errors.unable_to_load_graph") if ontology_subject.blank?
      ontology_subject_hash = convert_to_hash(ontology_subject)

      builder = Rdf::Builders::VocabBuilder.new
      builder.graph = @graph
      builder.build(ontology_subject_hash)
      raise Rdf::VocabImportJobError, I18n.t("rdf.errors.unable_to_load_vocab") if builder.attributes.blank?

      uri = builder.attributes[:uri]
      uri ||= Rdf::Vocab.normalize_uri(ontology_subject.to_s)

      vocab = Rdf::Vocab.site(@cur_site).where(uri: uri).first || Rdf::Vocab.new
      vocab.attributes = builder.attributes
      vocab.site_id = @cur_site.id
      vocab.prefix = @prefix
      vocab.owner = @owner
      vocab.order = @order if @order
      vocab.uri = uri
      save_or_update!(vocab)

      @vocabs << vocab
      @vocab_count += 1
    end

    def load_and_create_objects(vocab)
      rdf_objects = @graph.each.select do |statement|
        statement.predicate.pname == "rdf:type" && statement.object.pname != "owl:Ontology"
      end
      rdf_objects = rdf_objects.select do |statement|
        statement.subject.to_s.start_with?(vocab.uri)
      end
      rdf_objects = rdf_objects.select do |statement|
        statement.object.uri?
      end
      rdf_objects = rdf_objects.map(&:subject).to_a.uniq

      rdf_objects.each do |object|
        hash = convert_to_hash(object)

        klass, builder = create_builder(hash)
        next if builder.blank?

        builder.graph = @graph
        builder.vocab = vocab
        builder.build(hash)
        next if builder.attributes.blank?

        # puts "builder.attributes=#{builder.attributes}"
        if klass == Rdf::Prop
          name = object.to_s.gsub(/^#{vocab.uri}/, '')
          create_prop(vocab, name, builder.attributes)
        else
          attributes = builder.attributes.dup
          attributes[:vocab_id] = vocab.id
          attributes[:name] = object.to_s.gsub(/^#{vocab.uri}/, '')
          @pending_classes << [klass, attributes]
        end
      end
    end

    def create_builder(hash)
      klass, builder = nil
      case hash["rdf:type"].first.pname
      when "owl:ObjectProperty", "owl:DatatypeProperty", "rdf:Property" then
        # property
        klass = Rdf::Prop
        builder = Rdf::Builders::PropertyBuidler.new
        @property_count += 1
      when "owl:Class", "rdfs:Datatype", "dc:AgentClass", "rdfs:Class" then
        # class
        klass = Rdf::Class
        builder = Rdf::Builders::ClassBuidler.new
        @class_count += 1
      when "http://purl.org/dc/dcam/VocabularyEncodingScheme" then
      else
        Rails.logger.debug "unknown type: #{hash["rdf:type"].first.pname}"
      end

      [ klass, builder ]
    end

    def create_prop(vocab, name, attributes)
      rdf_object = Rdf::Prop.vocab(vocab).where(name: name).first || Rdf::Prop.new
      # domains and ranges are class reference. so we'll resolve class reference later.
      domains = attributes.delete(:domains)
      ranges = attributes.delete(:ranges)
      rdf_object.attributes = attributes
      rdf_object.vocab_id = vocab.id
      rdf_object.name = name
      # rdf_object.save!
      save_or_update!(rdf_object)

      @pending_prop_attributes << [ rdf_object.id, domains, ranges ] if domains.present? || ranges.present?
    end

    def do_process_pending_classes
      @pending_classes.each do |klass, attributes|
        # puts "attributes=#{attributes}"
        rdf_object = klass.where(vocab_id: attributes[:vocab_id]).where(name: attributes[:name]).first || klass.new
        # properties are property reference. it'll be resolve after.
        properties = attributes.delete(:properties)
        # sub_class_of is class reference. so we'll resolve class reference later.
        sub_class_of = attributes.delete(:sub_class_of)
        rdf_object.attributes = attributes
        save_or_update!(rdf_object)

        associate_class_and_propeties(rdf_object, properties) if properties.present?
        @pending_class_attributes << [ rdf_object, sub_class_of ] if sub_class_of.present?
      end
    end

    def save_or_update!(item)
      if item.new_record?
        item.save!
      else
        item.update!
      end
    end

    def associate_class_and_propeties(rdf_class, property_hashes)
      property_hashes.each do |property_hash|
        rdf_prop = Rdf::Prop.site(@cur_site).search(uri: property_hash[:property]).first
        if rdf_prop.blank?
          Rails.logger.debug "property not found: #{uri}"
          next
        end

        copy_class_ids = Array.new(rdf_prop.class_ids || [])
        copy_class_ids << rdf_class.id
        rdf_prop.class_ids = copy_class_ids
        rdf_prop.update!

        # check datatype mismatch
        # datatype = property_hash[:datatype]
        # if datatype.present?
        #   if rdf_prop.range.blank?
        #     rdf_prop.range = datatype
        #   elsif rdf_prop.range.uri != datatype
        #     puts "datatype mismatch for #{rdf_prop.name}: #{rdf_prop.range.uri} and #{datatype}"
        #     next
        #   end
        # end
      end
    end

    def do_process_pending_prop_attributes
      @pending_prop_attributes.each do |prop_id, domains, ranges|
        rdf_object = Rdf::Prop.site(@cur_site).find(prop_id)

        if domains.present?
          domain_classes = domains.map do |uri|
            rdf_class = Rdf::Class.site(@cur_site).search(uri: uri).first
            Rails.logger.debug "domain not found: #{uri}" if rdf_class.blank?
            rdf_class
          end

          copy_class_ids = Array.new(rdf_object.class_ids || [])
          copy_class_ids.concat(domain_classes.compact.map(&:_id))
          copy_class_ids.uniq!
          rdf_object.class_ids = copy_class_ids
        end

        if ranges.present?
          if ranges.length > 1
            Rails.logger.debug "multiple ranges are no longer supported."
          end
          range_class = Rdf::Class.site(@cur_site).search(uri: ranges.first).first
          if range_class.blank?
            Rails.logger.debug "range not found: #{ranges.first}"
            next
          end

          if rdf_object.range_id.blank?
            rdf_object.range_id = range_class.id
          elsif rdf_object.range_id != range_class.id
            Rails.logger.debug "property range missmatch for #{rdf_object.name}: #{rdf_object.range.uri} and #{ranges.first}"
          end
        end

        rdf_object.update!
      end
    end

    def do_process_pending_class_attributes
      @pending_class_attributes.each do |rdf_class, sub_class_of|
        sub_class = Rdf::Class.site(@cur_site).search(uri: sub_class_of).first
        if sub_class.blank?
          Rails.logger.debug "sub class not found: #{sub_class_of}"
          next
        end

        rdf_class.sub_class_id = sub_class.id
        rdf_class.update!
      end
    end
end
