class Cms::ApiToken < SS::ApiToken
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_sites", :edit

  def iss
    self.class.iss(site)
  end

  private

  def presence_node_id
    true
  end

  class << self
    def iss(site)
      "/.s#{site.id}"
    end

    def authenticate(request, opts = {})
      site = opts[:site]
      action = opts[:action].presence || "api_login"
      raise "site not given!" if site.nil?

      token = get_token(request)
      raise "could not fetch the token!" if token.nil?

      decoded_token = JWT.decode token, secret, true, { algorithm: 'HS256' }
      claim = decoded_token[0]
      raise "invalid iss!" if claim["iss"] != iss(site)

      api_token = self.site(site).where(jwt_id: claim["jti"]).first
      raise "could not found api token!" if api_token.nil?
      raise "api_token's state is closed!" if api_token.closed?

      right = SS::User.find(claim["aud"]) rescue nil
      left = api_token.audience
      raise "invalid aud!" if right.nil? || left.nil? || right.id != left.id

      yield api_token.audience if block_given?

      History::Log.create_log!(
        request, nil, controller: request.path, action: action,
        cur_site: site, cur_user: api_token.audience, item: api_token
      ) rescue nil

      api_token
    end

    def search(params)
      criteria = all
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
end
