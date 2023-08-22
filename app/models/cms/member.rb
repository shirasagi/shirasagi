class Cms::Member
  include Cms::Model::Member
  include ::Member::ExpirableSecureId
  include ::Member::Addon::AdditionalAttributes
  include ::Member::Addon::LineAttributes
  include ::Member::Addon::Bookmark
  include Ezine::Addon::Subscription

  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.freeze

  index({ site_email: 1 }, { unique: true, sparse: true })

  class << self
    def create_auth_member(auth, site)
      create! do |member|
        member.site_id = site.id
        member.state = 'enabled'
        member.oauth_type = auth.provider
        member.oauth_id = auth.uid
        member.oauth_token = auth.credentials.token
        member.name = name_of(auth.info)
      end
    end

    def name_of(info)
      # OmniAuth::AuthHash::InfoHash has insufficient implementation of name method
      # revise it
      name = info.name
      name = "#{info.first_name} #{info.last_name}".strip if name.blank? && (info.first_name? || info.last_name?)
      name = info.nickname if name.blank? && info.nickname?
      name = info.email if name.blank? && info.email?
      name = "(no name)" if name.blank?

      if EMAIL_REGEX.match?(name)
        authname = name.split(EMAIL_REGEX)
        name = name.gsub("@#{authname.last}", "")
      end

      name
    end

    def search(params = {})
      all.search_name(params).search_keyword(params).search_state(params)
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :name, :email, :kana, :organization_name, :job, :tel, :postal_code, :addr
    end

    def search_state(params)
      return all if params.blank? || params[:state].blank?
      all.where(state: params[:state])
    end

    def to_csv
      I18n.with_locale(I18n.default_locale) do
        CSV.generate do |data|
          data << %w(
            id state name email kana organization_name job tel
            postal_code addr sex birthday last_loggedin updated created
          ).map { |k| t(k) }

          criteria.each do |item|
            line = []
            line << item.id
            line << (item.state.present? ? I18n.t("cms.options.member_state.#{item.state}") : '')
            line << item.name
            line << item.email
            line << item.kana
            line << item.organization_name
            line << item.job
            line << item.tel
            line << item.postal_code
            line << item.addr
            line << (item.sex.present? ? I18n.t("member.options.sex.#{item.sex}") : '')
            line << item.birthday.try { |time| I18n.l(time.to_date, format: :picker) }
            line << item.last_loggedin.try { |time| I18n.l(time, format: :picker) }
            line << I18n.l(item.updated, format: :picker)
            line << I18n.l(item.created, format: :picker)
            data << line
          end
        end
      end
    end
  end
end
