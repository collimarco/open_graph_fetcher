# OpenGraphFetcher

Fetch Open Graph metadata in a safer way.

- Includes some mitigations for SSRF attacks
- Blocks private and local IP ranges
- Avoids TOC/TOU when connecting to the IP
- Supports only HTTPS on the standard port (443)
- Includes request timeouts
- Avoids redirects
- Allows only text/html responses
- Returns only known OG properties and nothing else

## Installation

```ruby
gem 'open_graph_fetcher'
```

## Usage

Basic usage:

```ruby
url = "https://ogp.me"
fetcher = OpenGraphFetcher::Fetcher.new(url)
og_data = fetcher.fetch
puts og_data
```

## License

The gem is available as open source under the terms of the MIT License.
