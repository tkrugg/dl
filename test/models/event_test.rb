require 'test_helper'

class EventTest < ActiveSupport::TestCase

	# KNOWN LIMITATIONS that aren't going to be tested
	# - openings starting on a day and ending 1 or more days later (in particular if opening spans over 7 days)

	test "one simple test example" do

		Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
		Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:30")

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal Date.new(2014, 8, 10), availabilities[0][:date]
		assert_equal [], availabilities[0][:slots]
		assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
		assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
		assert_equal Date.new(2014, 8, 16), availabilities[6][:date]
		assert_equal 7, availabilities.length
	end

	test "a full schedule, single appointment" do

		Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
		Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 09:30"), ends_at: DateTime.parse("2014-08-11 12:30")

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal 7, availabilities.length
		availabilities.each_with_index do |availability, index|
			assert_equal Date.new(2014, 8, 10 + index), availability[:date] # checking all dates appear in the right order
			assert_equal [], availability[:slots] # checking all slots are empty
		end
	end

	test "a full schedule, multiple appointments" do

		Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
		Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 09:30"), ends_at: DateTime.parse("2014-08-11 10:30")
		Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:00")
		Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 11:00"), ends_at: DateTime.parse("2014-08-11 12:30")

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal 7, availabilities.length
		availabilities.each_with_index do |availability, index|
			assert_equal Date.new(2014, 8, 10 + index), availability[:date] # checking all dates appear in the right order
			assert_equal [], availability[:slots] # checking all slots are empty
		end
	end

	test "no openings, 1 appointment" do

		Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 09:30"), ends_at: DateTime.parse("2014-08-11 10:30")

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal 7, availabilities.length
		availabilities.each_with_index do |availability, index|
			assert_equal Date.new(2014, 8, 10 + index), availability[:date] # checking all dates appear in the right order
			assert_equal [], availability[:slots] # checking all slots are empty
		end
	end

	test "1 non weekly recurring opening" do

		Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-14 09:30"), ends_at: DateTime.parse("2014-08-14 12:30"), weekly_recurring: false

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal 7, availabilities.length
		availabilities.each_with_index do |availability, index|
			assert_equal Date.new(2014, 8, 10 + index), availability[:date] # checking all dates appear in the right order
			if (availability[:date] == Date.parse("2014-08-14"))
				assert_equal ["9:30", "10:00", "10:30", "11:00", "11:30", "12:00"], availability[:slots]
			else
				assert_equal [], availability[:slots]
			end
		end
	end

	test "1 past non weekly recurring opening" do

		Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: false

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal 7, availabilities.length
		availabilities.each_with_index do |availability, index|
			assert_equal Date.new(2014, 8, 10 + index), availability[:date] # checking all dates appear in the right order
			assert_equal [], availability[:slots] # checking all slots are empty
		end
	end

	test "1 future non weekly recurring opening" do

		Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-20 09:30"), ends_at: DateTime.parse("2014-08-20 12:30"), weekly_recurring: false

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal 7, availabilities.length
		availabilities.each_with_index do |availability, index|
			assert_equal Date.new(2014, 8, 10 + index), availability[:date] # checking all dates appear in the right order
			assert_equal [], availability[:slots] # checking all slots are empty
		end
	end

	test "empty schedule" do

		Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true

		availabilities = Event.availabilities DateTime.parse("2014-08-10")
		assert_equal 7, availabilities.length
		availabilities.each_with_index do |availability, index|
			assert_equal Date.new(2014, 8, 10 + index), availability[:date]
			if (availability[:date] == Date.parse("2014-08-04") + 7.days)
				assert_equal ["9:30", "10:00", "10:30", "11:00", "11:30", "12:00"], availability[:slots]
			else
				assert_equal [], availability[:slots]
			end
		end
	end
end
