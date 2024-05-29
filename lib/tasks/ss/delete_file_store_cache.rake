namespace :ss do
  # Deletes all items from the cache
  task delete_file_store_cache: :environment do
    store, path = Rails.application.config.cache_store
    if store == :file_store
      puts "delete file_store cache"
      Rails.cache.clear
    end
  end

  # Preemptively iterates through all stored keys and removes the ones which have expired.
  # https://github.com/rails/rails/blob/6-1-stable/activesupport/lib/active_support/cache/file_store.rb#L42-L49
  task cleanup_file_store_cache: :environment do
    SS::CleanupFileStoreCacheJob.perform_now
  end
end
