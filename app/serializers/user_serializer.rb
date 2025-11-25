class UserSerializer < ApplicationSerializer
  attributes :id, :email, :name, :role, :created_at

  attribute :vendor_id do
    object.vendor_profile&.id if object.role == 'vendor'
  end
end


