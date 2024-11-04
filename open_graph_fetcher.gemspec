require_relative 'lib/open_graph_fetcher/version'

Gem::Specification.new do |s|
  s.name = 'open_graph_fetcher'
  s.version = OpenGraphFetcher::VERSION
  s.summary = 'Fetch Open Graph metadata in a safer way.'
  s.author = 'Marco Colli'
  s.homepage = 'https://github.com/collimarco/open_graph_fetcher'
  s.license = 'MIT'
  s.files = `git ls-files`.split("\n")
  s.add_dependency 'nokogiri'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
end
