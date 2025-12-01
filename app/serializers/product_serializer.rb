class ProductSerializer < ApplicationSerializer
  attributes :id, :vendor_id, :name, :description, :price, :images,
             :is_service, :duration, :available_time_slots

  has_many :product_options, serializer: ProductOptionSerializer, key: :options

  def images
    object.image_urls
  end

  def available_time_slots
    object.is_service? ? object.available_time_slots : nil
  end

  def duration
    object.is_service? ? object.duration : nil
  end
end


