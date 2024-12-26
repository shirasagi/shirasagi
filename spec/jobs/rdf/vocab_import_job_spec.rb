require 'spec_helper'

describe Rdf::VocabImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:class_list) { Rails.root.join("spec", "fixtures", "rdf", "class_list.txt") }
  let(:property_list) { Rails.root.join("spec", "fixtures", "rdf", "property_list.txt") }

  context "when IPA Core Vocab ttl is given" do
    let(:prefix) { "ic" }
    let(:file) { Rails.root.join("db", "seeds", "opendata", "rdf", "imicore242.ttl") }
    let(:order) { rand(999) }

    it "import from IPA Core Vocab ttl" do
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, order)
      expect(Rdf::Vocab.count).to eq 1
      vocab = Rdf::Vocab.first
      expect(vocab.prefix).to eq prefix
      expect(vocab.uri).to eq "http://imi.go.jp/ns/core/rdf#"
      expect(vocab.order).to eq order
      expect(vocab.labels.preferred_value).to eq "共通語彙基盤コア語彙"
      expect(vocab.comments.preferred_value).to include "コア語彙は、共通語彙基盤の基礎をなすもので、"
      expect(vocab.creators).to be_blank
      expect(vocab.license).to eq "http://creativecommons.org/publicdomain/zero/1.0/legalcode.ja"
      expect(vocab.version).to eq "2.4.2"
      expect(vocab.published).to eq "2019-02-15"
      expect(vocab.owner).to eq Rdf::Vocab::OWNER_SYSTEM
      expect(Rdf::Class.count).to eq vocab.classes.count
      expect(Rdf::Prop.count).to eq vocab.props.count

      expect(Rdf::Class.count).to be > 0
      File.open(class_list) do |file|
        file.each do |line|
          line.chomp!
          name = line.gsub(vocab.uri, '')
          rdf_object = Rdf::Class.where(vocab_id: vocab.id).where(name: name).first
          expect(rdf_object).not_to be_nil
        end
      end
      File.open(property_list) do |file|
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
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, 1000)
      expect(Rdf::Vocab.count).to eq 1
      expect(Rdf::Class.count).to be > 0
      expect(Rdf::Prop.count).to be > 0
    end
  end

  context "when XMLSchema ttl is given" do
    let(:prefix) { "xsd" }
    let(:file) { Rails.root.join("db", "seeds", "opendata", "rdf", "xsd.ttl") }
    let(:order) { rand(999) }

    it "import from XMLSchema ttl" do
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, order)
      expect(Rdf::Vocab.count).to eq 1
      Rdf::Vocab.first.tap do |vocab|
        expect(vocab.prefix).to eq prefix
        expect(vocab.uri).to eq "http://www.w3.org/2001/XMLSchema#"
        expect(vocab.order).to eq order
        expect(vocab.labels.preferred_value).to eq "XSD Namespace Document"
        expect(vocab.comments.preferred_value).to include "the XML Schema datatypes used in RDF/OWL"
        expect(vocab.creators).to include({ "homepage" => "http://sebastian.tramp.name" })
        expect(vocab.license).to be_blank
        expect(vocab.version).to be_blank
        expect(vocab.published).to be_blank
        expect(vocab.owner).to eq Rdf::Vocab::OWNER_SYSTEM
        expect(Rdf::Class.count).to eq vocab.classes.count
        expect(Rdf::Prop.count).to eq vocab.props.count
      end
      expect(Rdf::Class.count).to eq 35
      Rdf::Class.find_by(name: "string").tap do |rdf_class|
        expect(rdf_class.labels.preferred_value).to eq "string"
        expect(rdf_class.comments.preferred_value).to include "The string datatype represents character strings in XML."
        expect(rdf_class.categories).to be_blank
        expect(rdf_class.sub_class).to be_blank
      end
      expect(Rdf::Prop.count).to eq 0
    end
  end

  context "when DCMI Type ttl is given" do
    let(:prefix) { "dcmitype" }
    let(:file) { Rails.root.join("db", "seeds", "opendata", "rdf", "dctype.ttl") }
    let(:order) { rand(999) }

    it "import from XMLSchema ttl" do
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, order)
      expect(Rdf::Vocab.count).to eq 1
      Rdf::Vocab.first.tap do |vocab|
        expect(vocab.prefix).to eq prefix
        expect(vocab.uri).to eq "http://purl.org/dc/dcmitype/"
        expect(vocab.order).to eq order
        expect(vocab.labels.preferred_value).to eq "DCMI Type Vocabulary"
        expect(vocab.comments).to be_nil
        expect(vocab.creators).to include({ "homepage" => "http://purl.org/dc/aboutdcmi#DCMI" })
        expect(vocab.license).to be_blank
        expect(vocab.version).to be_blank
        expect(vocab.published).to eq "2012-06-14"
        expect(vocab.owner).to eq Rdf::Vocab::OWNER_SYSTEM
        expect(Rdf::Class.count).to eq vocab.classes.count
        expect(Rdf::Prop.count).to eq vocab.props.count
      end
      expect(Rdf::Class.count).to eq 12
      Rdf::Class.find_by(name: "Collection").tap do |rdf_class|
        expect(rdf_class.labels.preferred_value).to eq "Collection"
        expect(rdf_class.comments.preferred_value).to eq "An aggregation of resources."
        expect(rdf_class.categories).to be_blank
        expect(rdf_class.sub_class).to be_blank
      end
      Rdf::Class.find_by(name: "MovingImage").tap do |rdf_class|
        expect(rdf_class.labels.preferred_value).to eq "Moving Image"
        expect(rdf_class.comments.preferred_value).to include "visual representations imparting an impression of motion"
        expect(rdf_class.categories).to be_blank
        expect(rdf_class.sub_class).to eq Rdf::Class.find_by(name: "Image")
      end
      expect(Rdf::Prop.count).to eq 0
    end
  end

  context "when Dublin Core Metadata Element Set ttl is given" do
    let(:prefix) { "dc11" }
    let(:file) { Rails.root.join("db", "seeds", "opendata", "rdf", "dcelements.ttl") }
    let(:order) { rand(999) }

    it do
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, order)
      expect(Rdf::Vocab.count).to eq 1
      Rdf::Vocab.first.tap do |vocab|
        expect(vocab.prefix).to eq prefix
        expect(vocab.uri).to eq "http://purl.org/dc/elements/1.1/"
        expect(vocab.order).to eq order
        expect(vocab.labels.preferred_value).to eq "Dublin Core Metadata Element Set, Version 1.1"
        expect(vocab.comments).to be_nil
        expect(vocab.creators).to include({ "homepage" => "http://purl.org/dc/aboutdcmi#DCMI" })
        expect(vocab.license).to be_blank
        expect(vocab.version).to be_blank
        expect(vocab.published).to eq "2012-06-14"
        expect(vocab.owner).to eq Rdf::Vocab::OWNER_SYSTEM
        expect(Rdf::Class.count).to eq vocab.classes.count
        expect(Rdf::Prop.count).to eq vocab.props.count
      end
      expect(Rdf::Class.count).to eq 0
      expect(Rdf::Prop.count).to eq 15
      Rdf::Prop.find_by(name: "contributor").tap do |rdf_prop|
        expect(rdf_prop.labels.preferred_value).to eq "Contributor"
        expect(rdf_prop.comments.preferred_value).to include "An entity responsible for making contributions to the resource."
        expect(rdf_prop.range).to be_blank
      end
      Rdf::Prop.find_by(name: "type").tap do |rdf_prop|
        expect(rdf_prop.labels.preferred_value).to eq "Type"
        expect(rdf_prop.comments.preferred_value).to eq "The nature or genre of the resource."
        expect(rdf_prop.range).to be_blank
      end
    end
  end

  context "when Dublin Core Term ttl is given" do
    let(:prefix) { "dc" }
    let(:file) { Rails.root.join("db", "seeds", "opendata", "rdf", "dcterms.ttl") }
    let(:order) { rand(999) }

    it "import from Dublin Core Term ttl" do
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, order)
      expect(Rdf::Vocab.count).to eq 1
      Rdf::Vocab.first.tap do |vocab|
        expect(vocab.prefix).to eq prefix
        expect(vocab.uri).to eq "http://purl.org/dc/terms/"
        expect(vocab.order).to eq order
        expect(vocab.labels.preferred_value).to eq "DCMI Metadata Terms - other"
        expect(vocab.comments).to be_blank
        expect(vocab.creators).to include({ "homepage" => "http://purl.org/dc/aboutdcmi#DCMI" })
        expect(vocab.license).to be_blank
        expect(vocab.version).to be_blank
        expect(vocab.published).to eq "2012-06-14"
        expect(vocab.owner).to eq Rdf::Vocab::OWNER_SYSTEM
        expect(Rdf::Class.count).to eq vocab.classes.count
        expect(Rdf::Prop.count).to eq vocab.props.count
      end
      expect(Rdf::Class.count).to eq 34
      Rdf::Class.find_by(name: "FileFormat").tap do |rdf_class|
        expect(rdf_class.labels.preferred_value).to eq "File Format"
        expect(rdf_class.comments.preferred_value).to eq "A digital resource format."
        expect(rdf_class.categories).to be_blank
        expect(rdf_class.sub_class).to eq Rdf::Class.find_by(name: "MediaType")
      end
      # rdfs:DataType is also imported
      Rdf::Class.find_by(name: "ISO639-2").tap do |rdf_class|
        expect(rdf_class.labels.preferred_value).to eq "ISO 639-2"
        expect(rdf_class.comments.preferred_value).to include "The three-letter alphabetic codes"
        expect(rdf_class.categories).to be_blank
        expect(rdf_class.sub_class).to be_blank
      end
      expect(Rdf::Prop.count).to eq 55
      Rdf::Prop.find_by(name: "identifier").tap do |rdf_prop|
        expect(rdf_prop.labels.preferred_value).to eq "Identifier"
        expect(rdf_prop.comments.preferred_value).to include "An unambiguous reference to the resource"
        expect(rdf_prop.range).to be_blank
      end
      Rdf::Prop.find_by(name: "license").tap do |rdf_prop|
        expect(rdf_prop.labels.preferred_value).to eq "License"
        expect(rdf_prop.comments.preferred_value).to include "A legal document giving official permission"
        expect(rdf_prop.range).to eq Rdf::Class.find_by(name: "LicenseDocument")
      end
    end
  end

  context "when Friend of a Friend rdf is given" do
    let(:prefix) { "foaf" }
    let(:file) { Rails.root.join("spec", "fixtures", "rdf", "foaf.rdf.xml") }

    xit "import from Friend of a Friend rdf" do
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, 1000)
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
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, 1000)
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
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, 1000)
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

  context "when IMI Core Vocabulary 2.2 is given" do
    let(:prefix) { "ic" }
    let(:file) { Rails.root.join("spec/fixtures/rdf/ipa-core22.ttl") }
    let(:order) { rand(999) }

    xit "import from IPA Core Vocab ttl" do
      described_class.bind(site_id: site).perform_now(prefix, file.to_s, Rdf::Vocab::OWNER_SYSTEM, order)
      expect(Rdf::Vocab.count).to eq 1
      vocab = Rdf::Vocab.first
      expect(vocab.prefix).to eq prefix
      expect(vocab.uri).to eq "http://imi.ipa.go.jp/ns/core/rdf#"
      expect(vocab.order).to eq order
      expect(vocab.labels.preferred_value).to eq "共通語彙基盤コア語彙"
      expect(vocab.comments.preferred_value).to include "コア語彙は、共通語彙基盤の基礎をなすもので、"
      expect(vocab.creators).to be_blank
      expect(vocab.license).to eq "http://creativecommons.org/publicdomain/zero/1.0/"
      expect(vocab.version).to eq "2.2"
      expect(vocab.published).to eq "2015-02-03"
      expect(vocab.owner).to eq Rdf::Vocab::OWNER_SYSTEM
      expect(Rdf::Class.count).to eq vocab.classes.count
      expect(Rdf::Prop.count).to eq vocab.props.count
      expect(Rdf::Class.count).to eq 49
      Rdf::Class.find_by(name: "事物型").tap do |rdf_class|
        expect(rdf_class.labels.preferred_value).to eq "事物型"
        expect(rdf_class.comments.preferred_value).to eq "全ての型のベースとなる基本型。"
        expect(rdf_class.categories).to be_blank
        expect(rdf_class.sub_class).to be_blank
      end
      Rdf::Class.find_by(name: "ID型").tap do |rdf_class|
        expect(rdf_class.labels.preferred_value).to eq "ID型"
        expect(rdf_class.comments.preferred_value).to eq "識別子を表現するためのクラス"
        expect(rdf_class.categories).to be_blank
        expect(rdf_class.sub_class).to eq Rdf::Class.find_by(name: "事物型")
      end
      expect(Rdf::Prop.count).to eq 205
      Rdf::Prop.find_by(name: "Eメールアドレス").tap do |rdf_prop|
        expect(rdf_prop.labels.preferred_value).to eq "Eメールアドレス"
        expect(rdf_prop.comments.preferred_value).to eq "電子メールのメールアドレス"
        expect(rdf_prop.range).to be_blank
      end
      Rdf::Prop.find_by(name: "アクセス区間").tap do |rdf_prop|
        expect(rdf_prop.labels.preferred_value).to eq "アクセス区間"
        expect(rdf_prop.comments.preferred_value).to eq "アクセス方法の各区間の一覧"
        expect(rdf_prop.range).to eq Rdf::Class.find_by(name: "アクセス区間型")
      end
    end
  end
end
