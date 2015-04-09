class Rdf::Apis::PropsController < ApplicationController
  include Cms::ApiFilter

  model Rdf::Prop

  before_action :set_vocab_id

  private
    def vocab_options
      vocabs = Rdf::Vocab.site(@cur_site).each.select do |vocab|
        vocab.allowed?(:read, @cur_user, site: @cur_site)
      end
      vocabs.reduce([]) do |ret, vocab|
        ret << [ vocab.label, vocab.id ]
      end.to_a
    end

    def set_vocab_id
      params[:s] = {} if params[:s].blank?
      params[:s][:vocab] = Rdf::Vocab.site(@cur_site).first.id if params[:s][:vocab].blank?
    end

  public
    def index
      @vocab_options = vocab_options
      @items = @model.site(@cur_site).search(params[:s]).page(params[:page]).per(50)
    end
end
