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
          list = results.to_html
        elsif format == "JSON"
          list = results.to_json
        elsif format == "CSV"
          list = results.to_csv
        elsif format == "TSV"
          list = results.to_tsv
        elsif format == "XML"
          list = results.to_xml
        end

        return list
      end

end
end
