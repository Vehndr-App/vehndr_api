module Api
  class EmployeesController < BaseController
    before_action :authenticate_request
    before_action :set_vendor
    before_action :authorize_vendor, only: [:create, :update, :destroy]
    before_action :set_employee, only: [:show, :update, :destroy]

    def index
      employees = @vendor.employees
      render json: employees, each_serializer: EmployeeSerializer
    end

    def show
      render json: @employee, serializer: EmployeeSerializer
    end

    def create
      employee = @vendor.employees.build(employee_params)

      if employee.save
        render json: employee, serializer: EmployeeSerializer, status: :created
      else
        render json: { errors: employee.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @employee.update(employee_params)
        render json: @employee, serializer: EmployeeSerializer
      else
        render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @employee.destroy
      head :no_content
    end

    private

    def set_vendor
      @vendor = Vendor.find(params[:vendor_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Vendor not found' }, status: :not_found
    end

    def set_employee
      @employee = @vendor.employees.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Employee not found' }, status: :not_found
    end

    def authorize_vendor
      unless current_user&.vendor_profile == @vendor
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    def employee_params
      params.require(:employee).permit(:name, :email, :active)
    end
  end
end
