class VendorDetailSerializer < ApplicationSerializer
  attributes :id, :name, :description, :location, :rating, :categories

  attribute :hero_image do
    object.hero_image_url
  end

  has_many :products, serializer: ProductSerializer
end


