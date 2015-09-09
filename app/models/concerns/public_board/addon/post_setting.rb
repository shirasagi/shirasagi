module PublicBoard::Addon
  module PostSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :cur_date

    included do
      field :show_email, type: String, default: "enabled"
      field :show_url, type: String, default: "enabled"
      field :deletable_post, type: String, default: "enabled"
      field :deny_url, type: String, default: "deny"
      field :banned_words, type: SS::Extensions::Words, default: ""
      field :deny_ips, type: SS::Extensions::Words, default: ""
      field :text_size_limit, type: Integer, default: 400

      permit_params :show_email, :show_url, :deletable_post, :deny_url
      permit_params :banned_words, :deny_ips, :text_size_limit
    end

    public
      def show_email?
        show_email == "enabled"
      end

      def show_url?
        show_url == "enabled"
      end

      def deletable_post?
        deletable_post == "enabled"
      end

      def deny_url?
        deny_url == "deny"
      end

      def show_email_options
        [
          [I18n.t('public_board.options.show_email.enabled'), 'enabled'],
          [I18n.t('public_board.options.show_email.disabled'), 'disabled'],
        ]
      end

      def show_url_options
        [
          [I18n.t('public_board.options.show_url.enabled'), 'enabled'],
          [I18n.t('public_board.options.show_url.disabled'), 'disabled'],
        ]
      end

      def deletable_post_options
        [
          [I18n.t('public_board.options.deletable_post.enabled'), 'enabled'],
          [I18n.t('public_board.options.deletable_post.disabled'), 'disabled'],
        ]
      end

      def deny_url_options
        [
          [I18n.t('public_board.options.deny_url.deny'), 'deny'],
          [I18n.t('public_board.options.deny_url.allow'), 'allow'],
        ]
      end

      def text_size_limit_options
        [
          [I18n.t('public_board.options.text_size_limit.l400'), 400],
          [I18n.t('public_board.options.text_size_limit.l0'), 0],
        ]
      end
  end
end
