require 'spec_helper'

describe Rdf::Builders::BaseBuilder, dbscope: :example do
  class TestHandler < Rdf::Builders::BaseHandler
    def call(predicate, objects)
      context.attributes[:called] = 0x1fb1dc4f
    end
  end

  class TestBuilder < Rdf::Builders::BaseBuilder
    include Rdf::Builders::Context

    def initialize
      register_handler("rdfs:comment", TestHandler.new)
      alias_handler "dc:description", "rdfs:comment"
    end
  end

  describe "#call" do
    subject { TestBuilder.new }

    context "when handler is called" do
      it do
        expect(subject.call("rdfs:comment", [])).to be_truthy
        expect(subject.attributes[:called]).to eq 0x1fb1dc4f
      end
    end

    context "when alias is called" do
      it do
        expect(subject.call("dc:description", [])).to be_truthy
        expect(subject.attributes[:called]).to eq 0x1fb1dc4f
      end
    end

    context "when unregistered handler is called" do
      it do
        expect(subject.call("unk:unregistered", [])).to be_nil
        expect(subject.attributes[:called]).not_to eq 0x1fb1dc4f
      end
    end
  end
end
