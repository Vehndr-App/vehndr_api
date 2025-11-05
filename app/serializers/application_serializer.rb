class ApplicationSerializer < ActiveModel::Serializer
  # Transform keys to camelCase
  def self.transform_keys(hash)
    hash.deep_transform_keys { |key| key.to_s.camelize(:lower) }
  end

  def as_json(*args)
    hash = super
    self.class.transform_keys(hash)
  end
end


