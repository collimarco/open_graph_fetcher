require 'open_graph_fetcher'
require 'webmock/rspec'

RSpec.describe OpenGraphFetcher::Fetcher do

  before do
    allow(Resolv::DNS).to receive(:open).and_return("203.0.113.0")
  end

  describe ".fetch" do
    context "when fetching Open Graph data from a valid HTTPS URL" do
      it "successfully retrieves and parses Open Graph properties" do
        body = <<-HTML
          <html>
            <head>
              <meta property="og:title" content="Example Title">
              <meta property="og:type" content="website">
              <meta property="og:image" content="https://example.com/image.jpg">
              <meta property="og:url" content="https://example.com/example-page">
              <meta property="og:description" content="Example description">
            </head>
          </html>
        HTML
        
        stub_request(:get, "https://example.com/example-page").to_return(
          status: 200,
          body: body,
          headers: { "Content-Type" => "text/html" }
        )

        og_data = OpenGraphFetcher::Fetcher.fetch("https://example.com/example-page")

        expect(og_data).to eq({
          "title" => "Example Title",
          "type" => "website",
          "image" => "https://example.com/image.jpg",
          "url" => "https://example.com/example-page",
          "description" => "Example description"
        })
      end
    end

    context "when given an HTTP URL" do
      it "raises an InvalidSchemeError" do
        expect { OpenGraphFetcher::Fetcher.fetch("http://example.com") }.to raise_error(OpenGraphFetcher::InvalidSchemeError)
      end
    end

    context "when given a URL with a non-standard port" do
      it "raises an InvalidPortError" do
        expect { OpenGraphFetcher::Fetcher.fetch("https://example.com:8443") }.to raise_error(OpenGraphFetcher::InvalidPortError)
      end
    end
    
    context "when given a URL with an IP address" do
      it "raises an InvalidHostError" do
        expect { OpenGraphFetcher::Fetcher.fetch("https://203.0.113.0/test") }.to raise_error(OpenGraphFetcher::InvalidHostError)
      end
    end

    context "when the IP address cannot be resolved" do
      it "raises an IPResolutionError with an appropriate error message" do
        allow(Resolv::DNS).to receive(:open).and_raise(Resolv::ResolvError, "DNS resolution failed")

        expect { OpenGraphFetcher::Fetcher.fetch("https://nonexistent.example.com") }.to raise_error(OpenGraphFetcher::IPResolutionError, /Could not resolve IP: DNS resolution failed/)
      end
    end

    context "when the resolved IP address is private" do
      it "raises a PrivateIPError" do
        allow(Resolv::DNS).to receive(:open).and_return("10.0.0.1")

        expect { OpenGraphFetcher::Fetcher.fetch("https://ssrf.example.com") }.to raise_error(OpenGraphFetcher::PrivateIPError)
      end
    end

    context "when the HTTP response code is not 200" do
      it "raises a FetchError with the response code and message" do
        stub_request(:get, "https://example.com/nonexistent-page").to_return(
          status: 404,
          body: "Not Found"
        )

        expect { OpenGraphFetcher::Fetcher.fetch("https://example.com/nonexistent-page") }.to raise_error(OpenGraphFetcher::ResponseError, /HTTP response is not ok: HTTP 404/)
      end
    end

    context "when a network timeout occurs" do
      it "raises a FetchError with a timeout message" do
        stub_request(:get, "https://example.com").to_timeout

        expect { OpenGraphFetcher::Fetcher.fetch("https://example.com") }.to raise_error(OpenGraphFetcher::FetchError, /Request timed out/)
      end
    end

    context "when the URL returns a non-HTML content type" do
      it "raises an InvalidContentTypeError" do
        stub_request(:get, "https://example.com/non-html").to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" }
        )

        expect { OpenGraphFetcher::Fetcher.fetch("https://example.com/non-html") }.to raise_error(OpenGraphFetcher::InvalidContentTypeError)
      end
    end
  end
end
