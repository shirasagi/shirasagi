module Opendata::Sparql
  require "rdf/turtle"
  require "sparql/client"
  require "nkf"
  require "tempfile"

  # Fuseki Server
  SERVER  = SS.config.opendata.fuseki["host"]
  PORT    = SS.config.opendata.fuseki["port"]
  DATASET = SS.config.opendata.fuseki["dataset"]

  QUERY_SITE  = "http://#{SERVER}:#{PORT}/#{DATASET}/query".freeze
  UPDATE_SITE = "http://#{SERVER}:#{PORT}/#{DATASET}/update".freeze
  DATA_SITE   = "http://#{SERVER}:#{PORT}/#{DATASET}/data".freeze

  class << self
    public
      def disable?
        SS.config.opendata.fuseki["disable"].presence
      end

      def test?
        SS.config.opendata.fuseki["disable"] == "test"
      end

      def save(graph_name, ttl_url)
        dump("sparql#save:  #{graph_name}, #{ttl_url}") if test?
        return true if disable?

        begin

          temp_file = Tempfile.new("temp")
          open(ttl_url) do |f|
            f.each do |line|
              encoding = NKF.guess(line)
              temp_file.puts line.encode(Encoding::UTF_8, encoding)
            end
          end
          temp_file.close(false)

          temp_file.open

          triples = []
          graph = RDF::Graph.load(temp_file.path)
          graph.each do |statement|
            triples << statement.to_s
          end

          sparql = "INSERT DATA { GRAPH <#{graph_name}> { #{triples.join(" ")} } }"

          client = SPARQL::Client.new(UPDATE_SITE)
          client.update(sparql)

        rescue => e
          temp_file.close(true) if temp_file
          raise e
        ensure
          temp_file.close(true) if temp_file
        end

        return triples
      end

      def clear(graph_name)
        dump("sparql#clear: #{graph_name}") if test?
        return true if disable?

        client = SPARQL::Client.new(UPDATE_SITE)
        client.clear_graph(graph_name)
      end

      def clear_all
        return true if disable?

        client = SPARQL::Client.new(UPDATE_SITE)
        client.clear(:all)
      end

      def select(sparql_query, format = "HTML")
        return true if disable?

        client = SPARQL::Client.new(QUERY_SITE)
        results = client.query(sparql_query)

        if format == "HTML" || format == "HTML_TABLE"
          type = "text/html"
          ext = "html"
          encoding = Encoding::UTF_8
          data = results.to_html
        elsif format == "JSON"
          type = "application/json"
          ext = "json"
          encoding = Encoding::UTF_8
          data = results.to_json
        elsif format == "CSV"
          type = "text/csv"
          ext = "csv"
          encoding = Encoding::SJIS
          data = results.to_csv.encode(encoding)
        elsif format == "TSV"
          type = "text/plain"
          ext = "txt"
          encoding = Encoding::SJIS
          data = results.to_tsv.encode(encoding)
        elsif format == "XML"
          type = "application/xml"
          ext = "xml"
          encoding = Encoding::UTF_8
          data = results.to_xml
        end

        result = {
          type: type,
          ext: ext,
          encoding: encoding,
          data: data
        }

        return result
      end
  end
end
