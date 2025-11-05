class VendorDetailSerializer < ApplicationSerializer
  attributes :id, :name, :description, :hero_image, :location, :rating, :categories
  
  has_many :products, serializer: ProductSerializer
end


