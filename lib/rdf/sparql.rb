module Rdf::Sparql
  require "rdf/turtle"
  require "sparql/client"

  # Fuseki Server
  SERVER  = SS.config.opendata.server_address
  PORT    = SS.config.opendata.server_port
  DATASET = SS.config.opendata.dataset_name

  QUERY_SITE  = "http://#{SERVER}:#{PORT}/#{DATASET}/query"
  UPDATE_SITE = "http://#{SERVER}:#{PORT}/#{DATASET}/update"
  DATE_SITE   = "http://#{SERVER}:#{PORT}/#{DATASET}/data"

  class << self
    public
      def save(graph_name, ttl_url)

        client = SPARQL::Client.new(UPDATE_SITE)

         triples = []

         graph = RDF::Graph.load(ttl_url)
         graph.each do |statement|
          triples << statement.to_s
         end

         sparql = "INSERT DATA { GRAPH <#{graph_name}> { #{triples.join(" ")} } }"
         client.update(sparql)

         return triples
      end

      def clear(graph_name)
        client = SPARQL::Client.new(UPDATE_SITE)
        client.clear_graph(graph_name)
      end

      def clear_all
        client = SPARQL::Client.new(UPDATE_SITE)
        client.clear(:all)
      end

      def select(sparql_query, format = "HTML")

        client = SPARQL::Client.new(QUERY_SITE)
        results = client.query(sparql_query)

        if format == "HTML"
          type = "text/html"
          ext = "html"
          encoding = "utf-8"
          data = results.to_html
        elsif format == "JSON"
          type = "application/json"
          ext = "json"
          encoding = "utf-8"
          data = results.to_json
        elsif format == "CSV"
          type = "text/csv"
          ext = "csv"
          encoding = "sjis"
          data = results.to_csv
        elsif format == "TSV"
          type = "text/plain"
          ext = "txt"
          encoding = "sjis"
          data = results.to_tsv
        elsif format == "XML"
          type = "application/xml"
          ext = "xml"
          encoding = "utf-8"
          data = results.to_xml
        end

        result = {
          type: type,
          ext: ext,
          encoding: encoding,
          data: data.encode(encoding)
        }

        return result
      end

  end
end
