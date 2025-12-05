# frozen_string_literal: true

class VendorOrdersChannel < ApplicationCable::Channel
  def subscribed
    # Ensure user is authenticated and is a vendor
    if current_user && current_user.role == 'vendor' && current_user.vendor_profile
      vendor = current_user.vendor_profile
      stream_for vendor
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end

















