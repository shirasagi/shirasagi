class Cms::Member
  include Cms::Model::Member

  class << self
    public
      def create_auth_member(auth, site)
        create! do |member|
          member.site_id = site.id
          member.oauth_type = auth.provider
          member.oauth_id = auth.uid
          member.oauth_token = auth.credentials.token
          member.name = auth.info.name
          if member.name =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
            authname = auth.info.name.split(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i)
            member.name = member.name.gsub("@#{authname.last}", "")
          end
        end
      end
  end
end
