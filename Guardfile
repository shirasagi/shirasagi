# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rubocop, cli: '--rails' do
  watch(/.+\.rb$/)
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
