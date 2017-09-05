module SS::Model::MaxFileSize
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  attr_accessor :in_size_mb

  # Upload limit size (Bytes)
  # 104857600 = 100MB(1024*1024*100)
  MAX_FILE_SIZE = 104_857_600

  STATE_ENABLED = 'enabled'.freeze
  STATE_DISABLED = 'disabled'.freeze
  STATES = [STATE_ENABLED, STATE_DISABLED].freeze

  included do
    seqid :id
    field :name, type: String
    field :extensions, type: SS::Extensions::Words
    field :size, type: Integer
    field :order, type: Integer
    field :state, type: String

    permit_params :name, :extensions, :order, :state, :size
    permit_params :in_size_mb

    before_validation :set_size, if: ->{ in_size_mb }
    before_save :normalize_extensions
  end

  module ClassMethods
    def find_size(ext)
      item = where(state: STATE_ENABLED, :extensions.in => [ext.downcase, '*']).order_by(order: 1, name: 1, _id: -1).first
      return item.size if item.present?

      find_default_limit_size(ext)
    end

    def find_default_limit_size(ext)
      limit_size = SS.config.env.max_filesize_ext[ext.downcase]
      limit_size ||= SS.config.env.max_filesize
      limit_size ||= MAX_FILE_SIZE
      limit_size
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end

  def state_options
    STATES.map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }.to_a
  end

  private

  def set_size
    return if in_size_mb.blank?
    self.size = in_size_mb.to_i * 1_024 * 1_024
  end

  def normalize_extensions
    return if extensions.blank?
    # normalize extensions
    # 1. convert to downcase
    # 2. remove leading period
    self.extensions = extensions.map(&:downcase).map { |ext| ext.start_with?('.') ? ext[1..-1] : ext }
  end
end
