class Gws::Elasticsearch::Diagnostic::AnalyzersController < ApplicationController
  include Gws::BaseFilter

  navi_view "gws/elasticsearch/diagnostic/main/conf_navi"
  helper_method :analyzers, :tokenizers, :char_filters, :filters

  TOKENIZERS = %w(standard classic icu_tokenizer kuromoji_tokenizer ngram edge_ngram keyword).sort.freeze
  CHAR_FILTERS = %w(html_strip icu_normalizer kuromoji_iteration_mark).sort.freeze
  FILTERS = begin
    # standard filters
    filters = %w(
      apostrophe asciifolding cjk_bigram cjk_width edge_ngram kstem lowercase ngram porter_stem snowball stemmer stop
      truncate unique uppercase)

    # icu filters
    filters += %w(icu_folding)

    # kuromoji filters
    filters += %w(kuromoji_baseform kuromoji_part_of_speech kuromoji_readingform kuromoji_stemmer ja_stop kuromoji_number)

    filters.uniq.sort
  end.freeze

  class Analyzer
    include ActiveModel::Model
    attr_accessor :name, :tokenizer, :char_filters, :filters
  end

  class Item
    include ActiveModel::Model
    attr_accessor :text, :analyzer, :tokenizer, :char_filters, :filters
  end

  private

  def set_crumbs
    @crumbs << [ "Elasticsearch", gws_elasticsearch_diagnostic_main_path ]
    @crumbs << [ "Analyzer", url_for(action: :edit) ]
  end

  def analyzers
    @analyzers ||= begin
      index_name = "g#{@cur_site.id}"
      indices = @cur_site.elasticsearch_client.indices.get(index: index_name)
      indices.dig(index_name, "settings", "index", "analysis", "analyzer").map do |name, setting|
        Analyzer.new(
          name: name, tokenizer: setting["tokenizer"], char_filters: setting["char_filter"], filters: setting["filter"]
        )
      end
    end
  end

  def tokenizers
    TOKENIZERS
  end

  def char_filters
    CHAR_FILTERS
  end

  def filters
    FILTERS
  end

  def analyzer
    return @analyzer if instance_variable_defined?(:@analyzer)

    if params.dig(:item, :analyzer).present?
      analyzer_name = params.dig(:item, :analyzer).to_s
      @analyzer = analyzers.find { |analyzer| analyzer.name == analyzer_name }
      return @analyzer
    end

    @analyzer = analyzers.first
  end

  public

  def edit
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_groups)
    if @cur_site.elasticsearch_client.nil?
      head :not_found
      return
    end

    @item = Item.new(
      analyzer: analyzer.try(:name), tokenizer: analyzer.try(:tokenizer),
      char_filters: analyzer.try(:char_filters), filters: analyzer.try(:filters))
    render
  end

  def update
    if params.key?(:change_analyzer)
      @item = Item.new
      @item.attributes = params.require(:item).permit(:text)
      if analyzer
        @item.analyzer = analyzer.name
        @item.tokenizer = analyzer.tokenizer
        @item.char_filters = analyzer.char_filters
        @item.filters = analyzer.filters
      else
        @item.char_filters = []
        @item.filters = []
      end
      render action: "edit", layout: "ss/item_frame"
      return
    end

    @item = Item.new
    @item.attributes = params.require(:item).permit(:text, :analyzer, :tokenizer, char_filters: [], filters: [])
    if @item.text.blank?
      render action: "edit", layout: "ss/item_frame"
      return
    end

    body = { text: @item.text, tokenizer: @item.tokenizer, char_filter: @item.char_filters, filter: @item.filters }
    @result = @cur_site.elasticsearch_client.indices.analyze(index: "g#{@cur_site.id}", body: body)
    render action: "edit", layout: "ss/item_frame"
  end
end
