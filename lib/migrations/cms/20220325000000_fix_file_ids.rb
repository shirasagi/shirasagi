class SS::Migration20220325000000
  include SS::Migration::Base

  depends_on "20211011000000"

  def change
    repairer = Cms::FileRepair::Repairer.new
    all_ids = ::Cms::Site.all.pluck(:id)
    all_ids.each_slice(20) do |ids|
      ::Cms::Site.where(:id.in => ids).each do |site|
        puts "\# #{site.name}"
        repairer.fix_states(site)
      end
    end
  end
end
