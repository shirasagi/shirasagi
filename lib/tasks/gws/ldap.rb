module Tasks
  module Gws
    module Ldap
      module_function

      def sync
        ::Tasks::Gws::Base.each_sites do |site|
          Rails.logger.tagged(site.name) do
            task = ::Gws::Ldap::SyncTask.where(group_id: site).reorder(id: 1).first
            if task.blank?
              Rails.logger.info { "gws/ldap/sync_task is not defined on the site #{site.name}" }
              puts "#{site.name}: gws/ldap/sync_task is not defined"
              next
            end
            if task.admin_dn.blank?
              Rails.logger.info { "gws/ldap/sync_task is not properly configured on the site #{site.name}" }
              puts "#{site.name}: gws/ldap/sync_task is not properly configured"
              next
            end
            unless task.ready
              Rails.logger.info { "gws/ldap/sync_task is already started on the site #{site.name}" }
              puts "#{site.name}: #{I18n.t("ldap.messages.sync_already_started")}"
              next
            end

            puts site.name
            ::Gws::Ldap::SyncJob.bind(site_id: site, task_id: task).perform_now
          end
        end
      end
    end
  end
end
