namespace :services do
  desc "Backfill time slots for services that don't have any"
  task backfill_time_slots: :environment do
    puts "Starting time slots backfill..."

    services_without_slots = Product.services_only.where(
      "available_time_slots IS NULL OR available_time_slots = '{}'"
    )

    total_count = services_without_slots.count
    puts "Found #{total_count} service(s) without time slots"

    if total_count.zero?
      puts "No services need backfilling. All services have time slots!"
      next
    end

    updated_count = 0
    failed_count = 0

    services_without_slots.find_each do |service|
      begin
        service.update!(available_time_slots: Product.default_time_slots)
        updated_count += 1
        puts "✓ Updated #{service.name} (#{service.id})"
      rescue => e
        failed_count += 1
        puts "✗ Failed to update #{service.name} (#{service.id}): #{e.message}"
      end
    end

    puts "\n" + "="*50
    puts "Backfill complete!"
    puts "Total services processed: #{total_count}"
    puts "Successfully updated: #{updated_count}"
    puts "Failed: #{failed_count}"
    puts "="*50
  end

  desc "List all services and their time slot status"
  task list_time_slots: :environment do
    puts "\n" + "="*70
    puts "SERVICE TIME SLOTS STATUS"
    puts "="*70

    Product.services_only.find_each do |service|
      slots_count = service.available_time_slots&.length || 0
      booked_count = service.booked_time_slots&.length || 0
      available_count = service.currently_available_time_slots.length

      status = if slots_count.zero?
                 "❌ NO SLOTS"
               elsif available_count.zero?
                 "⚠️  ALL BOOKED"
               else
                 "✓ OK"
               end

      puts "\n#{status} #{service.name} (#{service.id})"
      puts "   Vendor: #{service.vendor.name}"
      puts "   Total slots: #{slots_count}"
      puts "   Booked: #{booked_count}"
      puts "   Available: #{available_count}"
    end

    puts "\n" + "="*70
  end
end
