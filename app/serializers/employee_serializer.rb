class EmployeeSerializer < ActiveModel::Serializer
  attributes :id, :vendor_id, :name, :email, :active, :created_at, :updated_at
end
