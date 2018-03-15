require 'net/http'
require 'json'
require 'yaml'
require 'time'

class OpenHack
  attr_reader :file, :url, :regex
  def initialize
    @groupname = 'openhack'
    @file = "data/events/#{@groupname}.yml"
    @url = 'https://api.meetup.com/Syracuse-Software-Development-Meetup/events?photo-host=public&page=20&sig_id=43509072&sig=828a46028303af23271ba163452545932284ce02'
    @regex = /open\s?hack/i
  end

  def build_event(from_meetup)
    date_time = DateTime.parse("#{from_meetup['local_date']} #{from_meetup['local_time']}")
    {
      'group' => @groupname,
      'name' => "OpenHack #{date_time.strftime('%B')}",
      'description' => "OpenHack is a casual social coding meetup with a simple purpose: Code together, on anything.",
      'rsvp_link' => from_meetup["link"],
      'date' => date_time.to_date,
      'time' => date_time.strftime('%-l:%M%P'),
      'location' => from_meetup["venue"]["name"]
    }
  end
end
class SyrJs
  attr_reader :file, :url, :regex
  def initialize
    @groupname = 'syr_js'
    @file = "data/events/#{@groupname}.yml"
    @url = 'https://api.meetup.com/Syracuse-Software-Development-Meetup/events?photo-host=public&page=20&sig_id=43509072&sig=828a46028303af23271ba163452545932284ce02'
    @regex = /javascript/i
  end

  def build_event(from_meetup)
    date_time = DateTime.parse("#{from_meetup['local_date']} #{from_meetup['local_time']}")
    puts "From meetup:"
    puts from_meetup.inspect
    {
      'group' => @groupname,
      'name' => from_meetup["name"],
      'description' => "We are a group dedicated to discussing and working with the JavaScript programming language.  Each event has both a learning and interactive portion. Whether you’re an experienced JavaScript programmer or just getting started, we welcome and encourage all proficiency levels.",
      'rsvp_link' => from_meetup["link"],
      'date' => date_time.to_date,
      'time' => date_time.strftime('%-l:%M%P'),
      'location' => from_meetup["venue"]["name"]
    }
  end
end
class WomenInCoding
  attr_reader :file, :url, :regex
  def initialize
    @groupname = 'women_in_coding'
    @file = "data/events/#{@groupname}.yml"
    @url = 'https://api.meetup.com/Syracuse-Tech-Meetup/events?photo-host=public&page=20&sig_id=43509072&sig=060c4d5452242b51d0c4137ceab5d5dd2873d709'
    @regex = /women in coding/i
  end

  def build_event(from_meetup)
    date_time = DateTime.parse("#{from_meetup['local_date']} #{from_meetup['local_time']}")
    puts "From meetup:"
    puts from_meetup.inspect
    {
      'group' => @groupname,
      'name' => from_meetup["name"],
      'description' => "Women in Coding host monthly workshop style classes that give you the chance to work on a project or work through an online curriculum at your own pace",
      'rsvp_link' => from_meetup["link"],
      'date' => date_time.to_date,
      'time' => date_time.strftime('%-l:%M%P'),
      'location' => from_meetup["venue"]["name"]
    }
  end
end


EVENTS = [OpenHack.new, SyrJs.new, WomenInCoding.new]

EVENTS.each do |event|
  puts "*"*40
  puts "Checking events for #{event.class}..."
  db = YAML.load_file(event.file)
  # if next event has a value is set
  if db["next"]
    next_date = db["next"]["date"]
    # nothing to do if next is in the future
    if next_date >  Date.today
      puts "next event is #{next_date} no need to update"
      next
    end

    puts "Previous next event:"
    puts db["next"].inspect

    # move old next to the past
    db["past"].unshift(db["next"])
    db["next"] = nil
  end

  # get event data from source
  response = Net::HTTP.get_response(URI(event.url))
  if response.code == "200"
    result = JSON.parse(response.body)
    events = result.select{|meetup| meetup["name"] =~ event.regex}

    if events.empty?
      puts "No upcoming events found"
    else
      # determine what events we're missing
      db_rsvp_links = db["past"].map{|past_event| past_event["rsvp_link"]}
      events_not_in_db = events.select{|from_meetup| !(db_rsvp_links.include?(from_meetup["link"])) }

      # get a new next
      next_event = event.build_event(events_not_in_db.first)
      puts "Adding next event: #{next_event.inspect}"
      db["next"] = next_event
    end

    # save
    File.open(event.file, "w+") do |f|
      f.write db.to_yaml
    end
  else
    puts "ERROR!!!"
  end
end
