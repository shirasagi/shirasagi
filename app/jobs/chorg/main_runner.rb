class Chorg::MainRunner < Chorg::Runner
  include Chorg::Runner::Main
  include Job::SS::Binding::Task

  self.task_class = Chorg::Task

  after_perform do
    # 管理画面のフォルダーツリーはキャッシュされている。組織変更を実行するとフォルダーツリーが不正になるかも。
    # そこで、キャッシュをクリアーする。
    # キャッシュ寿命が有効であっても消去したいので Rails.cache.clear を実行
    Rails.cache.clear rescue nil
  end
end
