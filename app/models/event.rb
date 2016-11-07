class Event < ActiveRecord::Base
	def self.availabilities(start_date)
		end_date = start_date + 7.days

		openings = Event.where("kind == ?", "opening")
		appointments = Event.where("kind == ?", "appointment")

		# let's work with 30 minutes slots
		slot_size = 30.minutes

		opening_slots = openings.flat_map do |opening|
			if (opening.weekly_recurring)
				occurence = opening.occurence_over_next_7_days(start_date)
				Event.get_slots(occurence[:starts_at], occurence[:ends_at], slot_size)
			elsif (start_date <= opening.starts_at and opening.ends_at <= end_date)
				Event.get_slots(opening.starts_at, opening.ends_at, slot_size)
			else
				[]
			end
		end

		busy_slots = appointments.flat_map do |appointment|
			slots = Event.get_slots(appointment.starts_at, appointment.ends_at, slot_size)
		end

		available_slots = opening_slots - busy_slots
		Event.render_as_weekly_schedule(start_date, end_date, available_slots)
	end

	def to_s
		"Event: #{self.starts_at} -> #{self.ends_at}"
	end

	# finds the occurence of self event within the 7 days following start_date
	def occurence_over_next_7_days(start_date)
		end_date = start_date + 7.days
		occ = {:starts_at => self.starts_at, :ends_at => self.ends_at}
		if weekly_recurring
			while self.weekly_recurring and occ[:starts_at] < start_date do
				occ[:starts_at] += 7.days
				occ[:ends_at] += 7.days
			end
			return occ
		elsif start_date < occ[:starts_at] and occ[:end_date] < end_date
			return occ
		end
	end


	# divides a time interval start_date..end_date into equal duration slots
	# a slot is referred to by its starting date
	# e.g. if start_date    == 2014-08-04 09:00
	#         end_date      == 2014-08-04 10:30
	#         slot_duration == 30.minutes
	#      we'd have 3 slots of 30 minutes
	#      - 2014-08-04 09:00 -> 2014-08-04 09:30
	#      - 2014-08-04 09:30 -> 2014-08-04 10:00
	#      - 2014-08-04 10:00 -> 2014-08-04 10:30
	#      This method will return their starting date as an array
	#      [2014-08-04 09:00, 2014-08-04 09:30, 2014-08-04 10:00]
	def self.get_slots(start_date, end_date, slot_duration)
		(start_date.to_i..end_date.to_i - slot_duration / 2).step(slot_duration).to_a
			.map{|t| Time.at(t).utc}
	end

	# another helper that groups a list of slots by day
	# For e.g.: if slots = [2014-08-04 09:00, 2014-08-04 09:30, 2014-08-05 10:00], output will be
	# {
	#    "2014-08-04" => [9:00, 9:30, 10:00]
	#    "2014-08-05" => [10:00]
	# }
	def self.group_by_day(slots, empty = false)
		slots.group_by { |slot| DateTime.parse(slot.strftime("%Y-%m-%d")) }
			.map{ |date, slots|
				[
					date,
					empty ? [] : slots.map{|slot| slot.strftime("%k:%M").strip}
				]
			}.to_h
	end

	# a helper that builds a schedule spanning over start_date..end_date end filled in with available_slots
	# output should look like [ {:date =>..., :slots => [...]}, ... ]
	def self.render_as_weekly_schedule(start_date, end_date, available_slots)
		blank_schedule = Event::group_by_day(Event.get_slots(start_date, end_date, 1.day), empty=true)
		availability_days = Event::group_by_day(available_slots)
		blank_schedule.merge(availability_days).map{|date, slots| {:date => date, :slots => slots}}
	end
end
