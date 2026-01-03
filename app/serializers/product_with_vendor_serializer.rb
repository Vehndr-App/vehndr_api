class ProductWithVendorSerializer < ApplicationSerializer
  attributes :id, :vendor_id, :name, :description, :price, :images,
             :is_service, :duration

  has_one :vendor, serializer: VendorSerializer
  has_many :product_options, serializer: ProductOptionSerializer, key: :options

  def images
    object.image_urls
  end

  def duration
    object.is_service? ? object.duration : nil
  end
end


