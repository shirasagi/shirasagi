class Board::Post
  include Board::Model::Post
  include SS::Reference::Site
  include Cms::Reference::Node
  include SS::Reference::User
  include Board::Addon::File
  include Board::Addon::PostPermission
  include SimpleCaptcha::ModelHelpers
  include Fs::FilePreviewable

  store_in_repl_master
  field :poster, type: String
  field :email, type: String
  field :poster_url, type: String
  field :delete_key, type: String
  permit_params :poster, :email, :poster_url, :delete_key

  apply_simple_captcha
  permit_params :captcha, :captcha_key

  validates :poster, presence: true
  validates :email, email: true
  validates :poster_url, url: true
  validates :node_id, presence: true

  validate :validate_text, if: -> { node.text_size_limit != 0 }
  validate :validate_delete_key, if: ->{ user.nil? && node.deletable_post? }
  validate :validate_banned_words, if: -> { node.banned_words.present? }
  validate :validate_deny_url, if: -> { node.deny_url? }

  def valid_with_captcha?(node)
    node.captcha_enabled? ? super() : true
  end

  def validate_text
    if text.size > node.text_size_limit
      errors.add :text, :too_long, count: node.text_size_limit
    end
  end

  def validate_delete_key
    unless /^[a-zA-Z0-9]{4}$/.match?(delete_key)
      errors.add :delete_key, I18n.t('board.errors.invalid_delete_key')
    end
  end

  def validate_banned_words
    cur_node.banned_words.each do |word|
      errors.add :name, :invalid_word, word: word if name.match?(/#{word}/)
      errors.add :text, :invalid_word, word: word if text.match?(/#{word}/)
      errors.add :poster, :invalid_word, word: word if poster.match?(/#{word}/)
    end
  end

  def validate_deny_url
    if %r{https?://[\w/:%#\$&\?\(\)~\.=\+\-]+}.match?(text)
      errors.add :text, I18n.t('board.errors.not_allow_urls')
    end
  end

  def file_previewable?(file, user:, member:)
    node.present? && node.public?
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
