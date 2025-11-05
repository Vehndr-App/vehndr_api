json.array! events do |event|
  json.id          event.id
  json.name        event.name
  json.description event.description
  json.location    event.location
  json.startDate   event.start_date
  json.endDate     event.end_date
  json.image       event.image
  json.category    event.category
  json.attendees   event.attendees
  json.status      event.status
  json.vendorIds   event.vendor_ids
end


