class Ezine::PublicEntry
  include Ezine::Entryable
  include Ezine::Addon::Data

  store_in session: :public, collection: :ezine_entries
end
