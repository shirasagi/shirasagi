require 'spec_helper'

describe Rdf::VocabImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:class_list) { Rails.root.join("spec", "fixtures", "rdf", "class_list.txt") }
  let(:property_list) { Rails.root.join("spec", "fixtures", "rdf", "property_list.txt") }

  context "when IPA Core Vocab ttl is given" do
    let(:prefix) { "ic" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "rdf.ttl") }

    it "import from IPA Core Vocab ttl" do
      described_class.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      vocab = Rdf::Vocab.first
      expect(Rdf::Class.count).to be > 0
      open(class_list) do |file|
        file.each do |line|
          line.chomp!
          name = line.gsub(vocab.uri, '')
          rdf_object = Rdf::Class.where(vocab_id: vocab.id).where(name: name).first
          expect(rdf_object).not_to be_nil
        end
      end
      open(property_list) do |file|
        file.each do |line|
          name, type, comment = line.chomp!.split("\t")
          break if name.blank?

          rdf_object = Rdf::Prop.where(vocab_id: vocab.id).where(name: name).first
          expect(rdf_object).not_to be_nil
        end
      end
    end
  end

  context "when IPA Core Vocab xml is given" do
    let(:prefix) { "ic" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "rdf.xml") }

    xit "import from IPA Core Vocab xml" do
      described_class.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      expect(Rdf::Class.count).to be > 0
      expect(Rdf::Prop.count).to be > 0
    end
  end

  context "when XMLSchema ttl is given" do
    let(:prefix) { "xsd" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "xsd.ttl") }

    xit "import from XMLSchema ttl" do
      described_class.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      expect(Rdf::Class.count).to be > 0
      expect(Rdf::Prop.count).to eq 0
    end
  end

  context "when Dublin Core Term ttl is given" do
    let(:prefix) { "dc" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "dcterms.ttl") }

    xit "import from Dublin Core Term ttl" do
      described_class.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      expect(Rdf::Class.count).to be > 0
      expect(Rdf::Prop.count).to be > 0
    end
  end

  context "when Friend of a Friend rdf is given" do
    let(:prefix) { "foaf" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "foaf.rdf.xml") }

    xit "import from Friend of a Friend rdf" do
      described_class.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      expect(Rdf::Class.count).to be > 0
      expect(Rdf::Prop.count).to be > 0
    end

    xit do
      graph = RDF::Graph.load(file, format: :rdfxml)
      puts "== dump =="
      graph.each do |statement|
        puts statement.inspect
      end
    end
  end

  context "when DBpedia Ontology rdf is given" do
    let(:prefix) { "dbpont" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "dbpedia_2014.owl.xml") }

    xit "import from DBpedia Ontology rdf" do
      described_class.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      expect(Rdf::Class.count).to be > 0
      expect(Rdf::Prop.count).to be > 0
    end

    xit do
      graph = RDF::Graph.load(file, format: :rdfxml)
      puts "== dump =="
      graph.each do |statement|
        puts statement.inspect
      end
    end
  end

  context "when WGS84 Geo Positioning is given" do
    let(:prefix) { "geo" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "wgs84_pos.xml") }

    xit "import from WGS84 Geo Positioning" do
      described_class.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      expect(Rdf::Class.count).to be > 0
      expect(Rdf::Prop.count).to be > 0
    end

    xit do
      graph = RDF::Graph.load(file, format: :rdfxml)
      puts "== dump =="
      graph.each do |statement|
        puts statement.inspect
      end
    end
  end
end
