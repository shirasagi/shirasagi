require 'spec_helper'

describe "rdf_turtle_fs" do
  context "when IPA Core Vocab is given" do
    before :all do
      @file = Rails.root.join("spec", "fixtures", "rdf", "rdf.ttl")
      @graph = RDF::Graph.load(@file, format: :ttl)
      @graph_array = @graph.each.to_a
    end

    describe "#count" do
      subject { @graph }
      its(:count) { should be > 0 }
    end

    describe "#first" do
      subject { @graph.first }
      its(:context) { should be_nil }
      its(:subject) { should eq RDF::URI::parse("http://imi.ipa.go.jp/ns/core/rdf") }
      its(:object) { should eq RDF::URI::parse("http://www.w3.org/2002/07/owl#Ontology") }
      it { expect(subject.predicate.property?).to be true }
      it { expect(subject.predicate.vocab.to_s).to eq "http://www.w3.org/1999/02/22-rdf-syntax-ns#" }
      it { expect(subject.predicate.attributes[:label]).to eq "type" }
    end

    describe "#[15]" do
      subject { @graph_array[15] }
      its(:context) { should be_nil }
      its(:subject) { should eq RDF::URI::parse("http://imi.ipa.go.jp/ns/core/rdf#ID") }
      its(:object) { should eq RDF::URI::parse("http://www.w3.org/2002/07/owl#ObjectProperty") }
      it { expect(subject.predicate.property?).to be true }
      it { expect(subject.predicate.vocab.to_s).to eq "http://www.w3.org/1999/02/22-rdf-syntax-ns#" }
      it { expect(subject.predicate.attributes[:label]).to eq "type" }
    end

    describe "#[16]" do
      subject { @graph_array[16] }
      its(:context) { should be_nil }
      its(:subject) { should eq RDF::URI::parse("http://imi.ipa.go.jp/ns/core/rdf#ID") }
      it { expect(subject.object.language).to eq :ja }
      it { expect(subject.object.value).to eq "ID" }
      it { expect(subject.predicate).to eq RDF::URI::parse("http://www.w3.org/2000/01/rdf-schema#label") }
    end

    describe "dump all predicate" do
      it do
        puts "all predicate"
        # predicates = @graph_array[0..14].to_enum.map do |s|
        #   s.predicate.qname
        # end
        predicates = @graph_array[15..@graph_array.length].to_enum.map do |s|
          s.predicate.qname
        end
        predicates = predicates.map do |prefix, value|
          "#{prefix}:#{value}"
        end
        puts predicates.to_a.uniq.sort
      end
    end

    describe "dump all type" do
      it do
        puts "all type"
        types = @graph.each.lazy.select do |s|
          s.predicate.qname == [:rdf, :type]
        end
        types = types.map do |s|
          s.object
        end
        types = types.to_a.uniq
        puts types
      end
    end
  end

  context "when XMLSchema is given" do
    before :all do
      @file = Rails.root.join("spec", "fixtures", "rdf", "xsd.ttl")
      @graph = RDF::Graph.load(@file, format: :ttl)
      @graph_array = @graph.each.to_a
    end

    it do
      puts "all triples"
      @graph_array.each do |s|
        puts s.inspect
      end
    end
  end

  context "when IPA Core Vocab is given" do
    before :all do
      @file = Rails.root.join("spec", "fixtures", "rdf", "dcterms.ttl")
      @graph = RDF::Graph.load(@file, format: :ttl)
      @graph_array = @graph.each.to_a
    end

    it do
      puts "all triples"
      @graph_array.each do |s|
        puts s.inspect
      end
    end
  end
end