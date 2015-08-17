class PublicBoard::Post
  include PublicBoard::Model::Post
  include SS::Reference::Site
  include Cms::Reference::Node
  include SS::Reference::User
  include PublicBoard::Addon::File
  include PublicBoard::Addon::PostPermission
  include SimpleCaptcha::ModelHelpers

  field :poster, type: String
  field :email, type: String
  field :poster_url, type: String
  field :delete_key, type: String
  permit_params :poster, :email, :poster_url, :delete_key

  apply_simple_captcha
  permit_params :captcha, :captcha_key

  validates :poster, presence: true
  validates :node_id, presence: true

  validate :validate_text, if: -> { node.text_size_limit != 0 }
  validate :validate_delete_key, if: ->{ user.nil? && node.deletable_post? }
  validate :validate_banned_words, if: -> { node.banned_words.present? }
  validate :validate_deny_url, if: -> { node.deny_url? }

  public
    def valid_with_captcha?(node)
      node.captcha_enabled? ? super() : true
    end

    def validate_text
      if text.size > node.text_size_limit
        errors.add :text, :too_long, count: node.text_size_limit
      end
    end

    def validate_delete_key
      if delete_key !~ /^[a-zA-Z0-9]{4}$/
        errors.add :delete_key, I18n.t('public_board.errors.invalid_delete_key')
      end
    end

    def validate_banned_words
      cur_node.banned_words.each do |word|
        errors.add :name, :invalid_word, word: word if name =~ /#{word}/
        errors.add :text, :invalid_word, word: word if text =~ /#{word}/
        errors.add :poster, :invalid_word, word: word if poster =~ /#{word}/
      end
    end

    def validate_deny_url
      if text =~ %r(https?://[\w/:%#\$&\?\(\)~\.=\+\-]+)
        errors.add :text, I18n.t('public_board.errors.not_allow_urls')
      end
    end

    def modified_text
      text = self.text
      text.gsub!(%r(https?://[\w/:%#\$&\?\(\)~\.=\+\-]+)) do |href|
        "<a href=\"#{href}\">#{href}</a>"
      end
      text.gsub(/(\r\n?)|(\n)/, "<br />").html_safe
    end

  class << self
    def to_csv
      csv = CSV.generate do |data|
        data << %w(name poster text email poster_url delete_key)
        criteria.each do |item|
          line = []
          line << item.name
          line << item.poster
          line << item.text
          line << item.email
          line << item.poster_url
          line << item.delete_key
          data << line
        end
      end
    end
  end
end
