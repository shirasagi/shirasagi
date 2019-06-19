class SS::SessionStore
  class << self
    def set_lifetime_limit(options)
      if options[:name]
        collection = ::Mongoid.client(options[:name]).database["sessions"]
      else
        # collection = ::MongoidStore::Session.collection
        collection = ::Mongoid.default_client.database["sessions"]
      end

      if collection.indexes.get("updated_at_1")
        collection.indexes.drop_one("updated_at_1")
      end

      collection.indexes.create_one({ updated_at: 1 }, { expire_after_seconds: options[:limit] })
    end
  end
end
