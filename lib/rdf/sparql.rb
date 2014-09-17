class Rdf::Sparql
  require "rdf/turtle"
  require "sparql/client"

  # Fusekiサーバー
  SERVER  = "192.168.230.128" # ローカル
  DATASET = "sample"

  QUERY_SITE  = "http://#{SERVER}:3030/#{DATASET}/query"
  UPDATE_SITE = "http://#{SERVER}:3030/#{DATASET}/update"
  DATE_SITE   = "http://#{SERVER}:3030/#{DATASET}/data"

  def initialize(logger)
    @logger = logger
  end

  def insert(graph_name, ttl_url)

    client = SPARQL::Client.new(UPDATE_SITE)

    triples = []

    graph = RDF::Graph.load(ttl_url)
    graph.each do |statement|
      triples << statement.to_s
    end

    sparql = "INSERT DATA { GRAPH <#{graph_name}> { #{triples.join(" ")} } }"
    client.update(sparql)
    @logger.info(sparql)

    return triples
  end

  def clear(graph_name)
    client = SPARQL::Client.new(UPDATE_SITE)
    client.clear_graph(graph_name)
  end

  def select(graph_name, format = "HTML")

    client = SPARQL::Client.new(QUERY_SITE)

    sparql = "PREFIX : <> SELECT * FROM NAMED <#{graph_name}> WHERE {?s ?p ?o .}"
    results = client.query(sparql)

    @logger.info("HTML : [" + results.to_html + "]")
    @logger.info("JSON : [" + results.to_json + "]")
    @logger.info("CSV  : [" + results.to_csv  + "]")
    @logger.info("TSV  : [" + results.to_tsv  + "]")
    @logger.info("XML  : [" + results.to_xml  + "]")

#    list = []
#    if !results.nil? then
#      @logger.info( "結果数 : [" + results.size.to_s + "]")
#      results.each do |solution|
#        result = {
#          :s => "#{solution[:s]}",
#          :p => "#{solution[:p]}",
#          :o => "#{solution[:o]}"
#        }
#        list << result
#      end
#    end

    if format == "HTML"
      list = results.to_html
    elsif format == "JSON" then
      list = results.to_json
    elsif format == "CSV" then
      list = results.to_csv
    elsif format == "TSV" then
      list = results.to_tsv
    elsif format == "XML" then
      list = results.to_xml
    end

    return list
  end

end
