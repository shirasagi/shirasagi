module Tasks
  module Gws
    module Affair
      class Notification
        class << self
          def deliver
            each_sites do |site|
              puts site.name
              ::Gws::Affair::NotifyCompensatoryFileJob.bind(site_id: site.id).perform_now
            end
          end

          private

          def each_sites
            name = ENV['site']
            if name
              ::Gws::Group.where(name: name).each do |site|
                yield site
              end
              return
            end

            all_ids = ::Gws::Group.all.where(name: { "$not" => /\// }).pluck(:id)
            all_ids.each_slice(20).each do |ids|
              ::Gws::Group.where(:id.in => ids).each do |site|
                yield site
              end
            end
          end
        end
      end
    end
  end
end
