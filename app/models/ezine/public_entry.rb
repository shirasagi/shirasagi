class Ezine::PublicEntry
  include Ezine::Entryable

  store_in session: :public, collection: :ezine_entries
end
