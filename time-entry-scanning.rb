require 'date'
def next_business_day(date)
  skip_weekends(date, 1)
end

def previous_business_day(date)
  skip_weekends(date, -1)
end

def skip_weekends(date, inc = 1)
  date += inc
  while date.wday == 0 || date.wday == 6
    date += inc
  end
  date
end

def last_business_day
  date = DateTime.now
  date -= 1
  while date.wday == 0 || date.wday == 6
    date += inc
  end
  date
end

puts last_business_day.strftime("%Y-%m-%d")
