# ファイルキャッシュ掃除ジョブ
#
# Preemptively iterates through all stored keys and removes the ones which have expired.
# https://github.com/rails/rails/blob/6-1-stable/activesupport/lib/active_support/cache/file_store.rb#L42-L49
class SS::CleanupFileStoreCacheJob < SS::ApplicationJob
  def perform
    store, _path = Rails.application.config.cache_store
    if store == :file_store
      puts "cleanup file_store cache"
      Rails.cache.cleanup
    end
  end
end
