require 'spec_helper'

describe Opendata::Sparql do
  before do
    @save_config = SS.config.opendata.fuseki
    SS::Config.replace_value_at(:opendata, 'fuseki', "disable" => false)
  end

  after do
    SS::Config.replace_value_at(:opendata, 'fuseki', @save_config)
  end

  describe ".save" do
    let(:ttl_file) { Rails.root.join('spec', 'fixtures', 'opendata', 'test-1.ttl').to_s }

    context "save success" do
      it do
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:update).and_return("this is stub")
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        ret = Opendata::Sparql.save unique_id, ttl_file
        expect(ret).to be_a Array
      end
    end

    context "save failed" do
      it do
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:update).and_raise(SocketError)
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        expect { Opendata::Sparql.save unique_id, ttl_file }.to raise_error SocketError
      end
    end
  end

  describe ".clear" do
    it do
      graph_name = unique_id
      sparql_client_stub = double('sparql client')
      allow(sparql_client_stub).to receive(:clear_graph).with(graph_name).and_return("this is stub")
      allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

      expect(Opendata::Sparql.clear(graph_name)).to eq "this is stub"
    end
  end

  describe ".clear_all" do
    it do
      sparql_client_stub = double('sparql client')
      allow(sparql_client_stub).to receive(:clear).with(:all).and_return("this is stub")
      allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

      expect(Opendata::Sparql.clear_all).to eq "this is stub"
    end
  end

  describe ".select" do
    context "when format is not given" do
      it do
        sparql_results_stub = double('sparql results')
        allow(sparql_results_stub).to receive(:to_html).and_return("<html></html>")
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:query).and_return(sparql_results_stub)
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        ret = Opendata::Sparql.select "query"
        expect(ret).to be_a Hash
        expect(ret).to include(type: "text/html", ext: "html", encoding: Encoding::UTF_8, data: "<html></html>")
      end
    end

    context "when format is HTML" do
      let(:format) { "HTML" }

      it do
        sparql_results_stub = double('sparql results')
        allow(sparql_results_stub).to receive(:to_html).and_return("<html></html>")
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:query).and_return(sparql_results_stub)
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        ret = Opendata::Sparql.select "query", format
        expect(ret).to be_a Hash
        expect(ret).to include(type: "text/html", ext: "html", encoding: Encoding::UTF_8, data: "<html></html>")
      end
    end

    context "when format is JSON" do
      let(:format) { "JSON" }

      it do
        sparql_results_stub = double('sparql results')
        allow(sparql_results_stub).to receive(:to_json).and_return("{\"a\":\"b\"}")
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:query).and_return(sparql_results_stub)
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        ret = Opendata::Sparql.select "query", format
        expect(ret).to be_a Hash
        expect(ret).to include(type: "application/json", ext: "json", encoding: Encoding::UTF_8, data: "{\"a\":\"b\"}")
      end
    end

    context "when format is CSV" do
      let(:format) { "CSV" }

      it do
        sparql_results_stub = double('sparql results')
        allow(sparql_results_stub).to receive(:to_csv).and_return("a,b,c")
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:query).and_return(sparql_results_stub)
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        ret = Opendata::Sparql.select "query", format
        expect(ret).to be_a Hash
        expect(ret).to include(type: "text/csv", ext: "csv", encoding: Encoding::SJIS, data: "a,b,c")
      end
    end

    context "when format is TSV" do
      let(:format) { "TSV" }

      it do
        sparql_results_stub = double('sparql results')
        allow(sparql_results_stub).to receive(:to_tsv).and_return("a\tb\tc")
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:query).and_return(sparql_results_stub)
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        ret = Opendata::Sparql.select "query", format
        expect(ret).to be_a Hash
        expect(ret).to include(type: "text/plain", ext: "txt", encoding: Encoding::SJIS, data: "a\tb\tc")
      end
    end

    context "when format is XML" do
      let(:format) { "XML" }

      it do
        sparql_results_stub = double('sparql results')
        allow(sparql_results_stub).to receive(:to_xml).and_return("<a><b><c /></b></a>")
        sparql_client_stub = double('sparql client')
        allow(sparql_client_stub).to receive(:query).and_return(sparql_results_stub)
        allow(SPARQL::Client).to receive(:new).and_return(sparql_client_stub)

        ret = Opendata::Sparql.select "query", format
        expect(ret).to be_a Hash
        expect(ret).to include(type: "application/xml", ext: "xml", encoding: Encoding::UTF_8, data: "<a><b><c /></b></a>")
      end
    end
  end
end
