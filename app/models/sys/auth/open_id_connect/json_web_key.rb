class Sys::Auth::OpenIdConnect::JsonWebKey
  extend SS::Translation
  include SS::Document

  field :kty, type: String
  field :kid, type: String
  field :alg, type: String
  field :others, type: Hash

  embedded_in :open_id_connect, inverse_of: :jwks, class_name: "Sys::Auth::OpenIdConnect"

  def to_jwk
    ::JSON::JWK.new(others.dup.merge(kty: kty, kid: kid))
  end
end
