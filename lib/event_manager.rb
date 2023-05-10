require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(phone)
  #removes dashes and keeps numbers
  phone.gsub!(/[^\d]/,'')

  if phone.length < 10
    puts phone
    return "bad number"

  elsif phone.length == 10
    return phone
  end

  if phone.length == 11 && phone[0] == 1
    return phone[1..]
  else
    puts phone
    return "bad number"
  end
end

def clean_hours(dates)
  #returns the hour in 24-hr time
  d = Time.strptime(dates, '%M/%d/%y %k:%M').strftime('%k')
  return d
end

def clean_days(dates)
  #returns the day of the week as a digit
  d = Date.strptime(dates, '%m/%d/%y').wday
  return d
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

best_hours = {}
best_days = {}
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = row[5]
  date = row[1]
  hour = clean_hours(date)
  day = clean_days(date)
  best_hours[hour] = 1 + best_hours.fetch(hour, 0)
  best_days[day] = 1 + best_days.fetch(day, 0)

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
puts best_hours
puts best_days