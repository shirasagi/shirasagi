class SS::Migration20150423044546
  def change
    Ezine::Page.all.each do |page|
      results = page[:results]
      next if results.empty?
      next if results.first.instance_of? Ezine::Result

      page.unset :results
      results
        .group_by.with_index { |e, i| i / 3 }.values
        .each do |result|
          page.results.create(
            started: result[0],
            delivered: result[1],
            count: result[2]
          )
        end
    end
  end
end
