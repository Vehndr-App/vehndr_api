class ProductOptionSerializer < ApplicationSerializer
  attributes :id, :option_id, :name, :option_type, :values
  
  def option_type
    object.option_type || 'select'
  end

  def id
    object.option_id
  end

  def option_id
    object.option_id
  end
end


