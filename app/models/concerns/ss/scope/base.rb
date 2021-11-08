module SS::Scope::Base
  extend ActiveSupport::Concern

  included do
    class_variable_set(:@@_text_index_fields, [])

    scope :search_text, ->(words) {
      words = words.split(/[\s　]+/).uniq.compact.map { |w| /#{::Regexp.escape(w)}/i } if words.is_a?(String)
      if self.class_variable_get(:@@_text_index_fields).present?
        all_in text_index: words
      else
        all_in name: words
      end
    }
    scope :without_deleted, ->(date = Time.zone.now) {
      where('$or' => [{ deleted: nil }, { :deleted.gt => date }])
    }
    scope :only_deleted, ->(date = Time.zone.now) {
      where(:deleted.lt => date)
    }
  end

  module ClassMethods
    def with_scope_ss(criteria)
      save = Mongoid::Threaded.current_scope(self)
      Mongoid::Threaded.set_current_scope(criteria, self)
      begin
        yield criteria
      ensure
        Mongoid::Threaded.set_current_scope(save, self)
      end
    end

    def new_scope_without_default(&block)
      without_default_scope do
        with_scope_ss(Mongoid::Criteria.new(self), &block)
      end
    end

    def keyword_in(words, *fields)
      options = fields.extract_options!
      method = options[:method].presence || 'and'

      words = words.split(/[\s　]+/).uniq.compact.map { |w| /#{::Regexp.escape(w)}/i } if words.is_a?(String)
      words = words[0..4]
      cond  = words.map do |word|
        { "$or" => fields.map { |field| { field => word } } }
      end
      method == 'and' ? all.and(cond) : all.where("$or" => cond)
    end

    def text_index(*args)
      fields = class_variable_get(:@@_text_index_fields)

      if args[0].is_a?(Hash)
        opts = args[0]
        if opts[:only]
          fields = opts[:only]
        elsif opts[:except]
          fields.reject! { |m| opts[:except].include?(m) }
        end
      else
        fields += args
      end

      class_variable_set(:@@_text_index_fields, fields)
    end

    # Mongoid では find_in_batches が存在しない。
    # find_in_batches のエミュレーションを提供する。
    #
    # ActiveRecord の find_in_batches と異なる点がある。
    #
    # ActiveRecord の find_in_batches では、start オプションを取るが、本メソッドは offset オプションを取る。
    # start オプションは主キーを取るが、offset オプションは読み飛ばすレコード数を取る。
    #
    # ActiveRecord の find_in_batches では、order_by が無効になるが、本メソッドでは order_by が有効である。
    #
    # @return [Enumerator<Array<self.class>>]
    def find_in_batches(options = {})
      unless block_given?
        return to_enum(:find_in_batches, options)
      end

      batch_size = options[:batch_size] || 1000
      offset = options[:offset] || 0
      records = self.limit(batch_size).skip(offset).to_a
      while records.any?
        records_size = records.size
        with_scope(Mongoid::Criteria.new(self)) do
          yield records
        end
        break if records_size < batch_size
        offset += batch_size
        records = self.limit(batch_size).skip(offset).to_a
      end
    end

    # Mongoid では find_each が存在しない。
    # find_each のエミュレーションを提供する。
    #
    # ActiveRecord の find_in_batches と異なる点がある。
    #
    # ActiveRecord の find_in_batches では、start オプションを取るが、本メソッドは offset オプションを取る。
    # start オプションは主キーを取るが、offset オプションは読み飛ばすレコード数を取る。
    #
    # ActiveRecord の find_in_batches では、order_by が無効になるが、本メソッドでは order_by が有効である。
    #
    # @return [Enumerator<self.class>]
    def find_each(options = {}, &block)
      unless block_given?
        return to_enum(:find_each, options)
      end

      find_in_batches(options) do |records|
        records.each(&block)
      end
    end
  end
end
