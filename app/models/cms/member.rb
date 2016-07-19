class Cms::Member
  include Cms::Model::Member
  include ::Member::ExpirableSecureId
  include ::Member::Addon::AdditionalAttributes
  include Ezine::Addon::Subscription

  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  index({ site_email: 1 }, { unique: true, sparse: true })

  class << self
    def create_auth_member(auth, site)
      create! do |member|
        member.site_id = site.id
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

      if name =~ EMAIL_REGEX
        authname = name.split(EMAIL_REGEX)
        name = name.gsub("@#{authname.last}", "")
      end

      name
    end

    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :email, :kana, :organization_name, :job, :tel, :postal_code, :addr
      end
      criteria
    end

    def to_csv
      CSV.generate do |data|
        data << %w(id state name email kana organization_name job tel postal_code addr sex birthday updated created)
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
          line << item.birthday.try(:strftime, "%Y/%m/%d")
          line << item.updated.strftime("%Y/%m/%d %H:%M")
          line << item.created.strftime("%Y/%m/%d %H:%M")
          data << line
        end
      end
    end
  end
end
