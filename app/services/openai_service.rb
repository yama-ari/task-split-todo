require 'openai'

class OpenaiService
  def self.call(prompt)
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end
