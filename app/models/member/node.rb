module Member::Node
  class Login
    include Cms::Node::Model
    include Member::Addon::Redirection
    include Member::Addon::FormAuth
    include Member::Addon::TwitterOauth
    include Member::Addon::FacebookOauth
    include Member::Addon::YahooJpOauth
    include Member::Addon::GoogleOauth
    include Member::Addon::GithubOauth

    default_scope ->{ where(route: "member/login") }
  end
end
