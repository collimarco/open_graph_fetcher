require 'open_graph_fetcher'

url = "https://ogp.me"
fetcher = OpenGraphFetcher::Fetcher.new(url)
og_data = fetcher.fetch
puts og_data
