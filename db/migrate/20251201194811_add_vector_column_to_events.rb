class AddVectorColumnToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :embedding, :vector,
      limit: LangchainrbRails
        .config
        .vectorsearch
        .llm
        .default_dimensions
  end
end
