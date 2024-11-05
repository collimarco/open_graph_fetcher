require 'nokogiri'
require 'net/http'
require 'resolv'
require 'ipaddr'

module OpenGraphFetcher
  class Fetcher
    OG_PROPERTIES = %w[title type image url description].freeze
    
    DNS_TIMEOUT = 3
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 3

    def self.fetch(url)
      new(url).fetch
    end

    def initialize(url)
      @url = url
    end

    def fetch
      uri = parse_uri(@url)
      raise InvalidSchemeError, "Only HTTPS URLs are allowed" unless uri.scheme == "https"
      raise InvalidPortError, "Only the default HTTPS port (443) is allowed" if uri.port && uri.port != 443
      raise InvalidHostError, "Using an IP as host is not allowed" if ip_address?(uri.hostname)

      ip_address = resolve_ip(uri)
      raise PrivateIPError, "Resolved IP address is in a private or reserved range" if private_ip?(ip_address)

      response = fetch_data(uri, ip_address)
      raise ResponseError, "HTTP response is not ok: HTTP #{response.code} #{response.message}" unless response.code == "200"
      raise InvalidContentTypeError, "Only HTML content is allowed" unless html_content?(response)
      
      parse_open_graph_data(response.body)
    end

    private
    
    def parse_uri(url)
      URI.parse(url)
    rescue URI::InvalidURIError => e
      raise InvalidURIError, "Could not parse URI: #{e.message}"
    end

    def resolve_ip(uri)
      Resolv::DNS.open do |dns|
        dns.timeouts = DNS_TIMEOUT
        dns.getaddress(uri.hostname).to_s
      end
    rescue Resolv::ResolvError => e
      raise IPResolutionError, "Could not resolve IP: #{e.message}"
    end
    
    def ip_address?(host)
      host =~ Resolv::IPv4::Regex || host =~ Resolv::IPv6::Regex
    end

    def private_ip?(ip)
      ip_addr = IPAddr.new(ip)
      ip_addr.private? || ip_addr.link_local? || ip_addr.loopback?
    end

    def fetch_data(uri, ip)
      request = Net::HTTP::Get.new(uri.request_uri)
      Net::HTTP.start(uri.hostname, uri.port, ipaddr: ip, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.request(request)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise FetchError, "Request timed out: #{e.message}"
    rescue StandardError => e
      raise FetchError, "Failed to fetch data: #{e.message}"
    end

    def html_content?(response)
      content_type = response["Content-Type"]
      content_type&.start_with?("text/html")
    end

    def parse_open_graph_data(html)
      doc = Nokogiri::HTML(html)
      og_data = {}

      OG_PROPERTIES.each do |property|
        meta_tag = doc.at_css("meta[property='og:#{property}']")
        og_data[property] = meta_tag[:content] if meta_tag && meta_tag[:content]
      end

      og_data
    end
  end
end
