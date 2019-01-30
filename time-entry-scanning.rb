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
