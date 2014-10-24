Dir.chdir @root = File.dirname(__FILE__)
@site = SS::Site.find_by host: ENV["site"]

## -------------------------------------

Fs.rm_rf(@site.path)
puts "delete document root: #{@site.path}"

resp = Cms::Layout.destroy_all site_id: @site.id
puts "delete #{resp} layouts"

resp = Cms::Node.destroy_all site_id: @site.id
puts "delete #{resp} nodes"

resp = Cms::Part.destroy_all site_id: @site.id
puts "delete #{resp} parts"

resp = Cms::Page.destroy_all site_id: @site.id
puts "delete #{resp} pages"

resp = SS::File.destroy_all site_id: @site.id
puts "delete #{resp} files"
