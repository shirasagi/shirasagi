class Cms::Member
  include Cms::Model::Member

  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.freeze

  class << self
    public
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
  end
end
