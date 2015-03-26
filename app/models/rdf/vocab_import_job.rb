class Rdf::VocabImportJob
  include Job::Worker
  include Rdf::Builders::Traversable

  public
    def call(host, prefix, file, owner = Rdf::Vocab::OWNER_USER)
      @cur_site = SS::Site.find_by(host: host)
      @prefix = prefix
      @graph = RDF::Graph.load(file, format: format_of(file))
      @owner = owner
      @vocabs = []
      @vocab_count = 0
      @class_count = 0
      @property_count = 0

      load_and_create_vocab
      @vocabs.each do |vocab|
        load_and_create_objects(vocab)
      end

      Rails.logger.info("imported from #{file}: vocab count=#{@vocab_count}, class count=#{@class_count}, " \
        "property count=#{@property_count}")
    end

  private
    def format_of(file)
      case File.extname(file).downcase
      when ".ttl" then
        :ttl
      when ".xml" then
        :rdfxml
      else
        :ttl
      end
    end

    def load_and_create_vocab
      ontology_subject = @graph.each.first.subject
      ontology_subject_hash = convert_to_hash(ontology_subject)

      builder = Rdf::Builders::VocabBuilder.new
      builder.graph = @graph
      builder.build(ontology_subject_hash)
      return if builder.attributes.blank?

      vocab = Rdf::Vocab.new
      vocab.attributes = builder.attributes
      vocab.site_id = @cur_site.id
      vocab.prefix = @prefix
      vocab.owner = @owner
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
