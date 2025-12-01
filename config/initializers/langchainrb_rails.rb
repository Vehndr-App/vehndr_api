# frozen_string_literal: true

LangchainrbRails.configure do |config|
  config.vectorsearch = Langchain::Vectorsearch::Pgvector.new(
    llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"], llm_options: {}, default_options: { chat_model: 'gpt-5-nano-2025-08-07' } )
  )
end
