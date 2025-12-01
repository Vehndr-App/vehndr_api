require 'uri'
require 'open-uri'

class EventFromUrlService
  class InvalidUrlError < StandardError; end
  class ScrapingError < StandardError; end

  def self.call(url)
    new(url).call
  end

  def initialize(url)
    @url = url
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    validate_url!
    scrape_event_data
  end

  private

  attr_reader :url

  def validate_url!
    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      raise InvalidUrlError, "Invalid URL format. Must be an HTTP or HTTPS URL."
    end
  rescue URI::InvalidURIError
    raise InvalidUrlError, "Invalid URL format"
  end

  def scrape_event_data
    webpage_content = fetch_webpage_content
    raise ScrapingError, "Failed to fetch webpage content" unless webpage_content

    event_details = fetch_event_details(webpage_content)
    raise ScrapingError, "Failed to extract event details" unless event_details

    event_details
  rescue StandardError => e
    Rails.logger.error "Event scraping error for #{@url}: #{e.message}"
    raise ScrapingError, e.message
  end

  def fetch_webpage_content
    URI.open(@url).read
  rescue OpenURI::HTTPError, SocketError => e
    Rails.logger.error "Failed to fetch URL #{@url}: #{e.message}"
    nil
  end

  def fetch_event_details(webpage_content)
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: "Extract event details from this webpage content: #{webpage_content}"
          }
        ],
      }
    )

    parse_gpt_response(response)
  rescue StandardError => e
    Rails.logger.error "GPT API error: #{e.message}"
    nil
  end

  def system_prompt
    <<~PROMPT
      You are an expert at extracting event information from webpages.
      Analyze the provided webpage content and extract the following event details in JSON format:
      {
        "name": "event name",
        "description": "detailed event description or info explaining what this event is",
        "location": "venue name or full address",
        "start_date": "YYYY-MM-DDTHH:MM:SS",
        "end_date": "YYYY-MM-DDTHH:MM:SS",
        "image": "URL to event image if present on page",
        "category": "event category (e.g., Music, Food, Sports, Art, Business, etc.)",
        "attendees": expected number of attendees as integer
      }

      Rules:
      - Use null for any fields you cannot find
      - Format dates as YYYY-MM-DDTHH:MM:SS (ISO 8601)
      - For end_date, if not specified, estimate based on typical event duration
      - Keep descriptions concise but informative (200-500 words)
      - Include only factual information from the webpage
      - For category, choose the most appropriate single category
      - For attendees, use 0 if not specified
      - For image, extract the main event promotional image URL if available
    PROMPT
  end

  def parse_gpt_response(response)
    return nil unless response.dig("choices", 0, "message", "content")

    json_response = JSON.parse(response["choices"][0]["message"]["content"])

    {
      name: json_response["name"],
      description: json_response["description"],
      location: json_response["location"],
      start_date: parse_datetime(json_response["start_date"]),
      end_date: parse_datetime(json_response["end_date"]),
      image: json_response["image"],
      category: json_response["category"],
      attendees: json_response["attendees"]&.to_i || 0,
      status: determine_status(parse_datetime(json_response["start_date"]))
    }
  end

  def parse_datetime(datetime_str)
    return nil if datetime_str.nil?
    DateTime.parse(datetime_str)
  rescue ArgumentError, TypeError
    nil
  end

  def determine_status(start_date)
    return "upcoming" unless start_date

    if start_date > DateTime.now
      "upcoming"
    elsif start_date > 30.days.ago
      "active"
    else
      "past"
    end
  end
end
