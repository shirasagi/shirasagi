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
        @vocab_count = 0
        @class_count = 0
        @property_count = 0

        load_and_create_vocab
        @vocabs.each do |vocab|
          load_and_create_objects(vocab)
        end

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

      vocab = Rdf::Vocab.new
      vocab.attributes = builder.attributes
      vocab.site_id = @cur_site.id
      vocab.prefix = @prefix
      vocab.owner = @owner
      vocab.order = @order if @order
      vocab.uri = ontology_subject.to_s unless builder.attributes.key?(:uri)
      vocab.save!

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

        case hash["rdf:type"].first.pname
        when "owl:ObjectProperty", "owl:DatatypeProperty", "rdf:Property" then
          # property
          klass = Rdf::Prop
          builder = Rdf::Builders::PropertyBuidler.new
          builder.graph = @graph
          builder.vocab = vocab
          builder.build(hash)
          @property_count += 1
        when "owl:Class", "rdfs:Datatype", "dc:AgentClass", "rdfs:Class" then
          # class
          klass = Rdf::Class
          builder = Rdf::Builders::ClassBuidler.new
          builder.graph = @graph
          builder.vocab = vocab
          builder.build(hash)
          @class_count += 1
        when "http://purl.org/dc/dcam/VocabularyEncodingScheme" then
          next
        else
          puts "unknown type: #{hash["rdf:type"].first.pname}"
          next
        end

        next if builder.attributes.blank?

        # puts "builder.attributes=#{builder.attributes}"
        # puts "object.to_s=#{object.to_s}"
        rdf_object = klass.new
        rdf_object.attributes = builder.attributes
        rdf_object.vocab_id = vocab.id
        rdf_object.name = object.to_s.gsub(/^#{vocab.uri}/, '')
        rdf_object.save!
      end
    end
end
