namespace :gws do
  namespace :workflow2 do
    # ワークフローの承認ルート設定をワークフロー2へ移行（コピー）するタスク
    task migrate_route: :environment do
      ::Tasks::Gws::Workflow2.migrate_route
    end
  end
end
