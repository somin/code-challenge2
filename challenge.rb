require 'json'

# Runs the program and catches any exceptions
def main
	begin
		run
	rescue => e
		# Print an error and alert the user
		puts "Error running challenge.rb:"
		raise
	else
		puts "\nchallenge.rb COMPLETE"
	end
end

# Read input JSON files
def read_files 
	begin 
		users_data = JSON.parse(File.read('users.json'))
		companies_data = JSON.parse(File.read('companies.json'))
	rescue => e
		puts "Error reading input files (verify they exist and are proper JSON):"
		raise
	else
		return users_data, companies_data
	end
end

# Returns true if the given company object has all required fields with the correct types
def validate_company(company)
	field_types = [
		['id', Integer],
		['name', String],
		['top_up', Integer]
	]

	field_types.each do |field_type|
		field = field_type[0]
		if !company.key?(field)
			puts "Missing field #{field} for company #{company}"
			return false
		end

		if company[field].class != field_type[1]
			puts "Company field #{field} incorrect type for company #{company}"
			return false
		end
	end

	# Do  a special check for boolean on email_status since I cant use the same logic above
	if !company.key?('email_status') 
		puts "Missing email_status field for company #{company}"
		return false
	end
	if ![true, false].include? company['email_status']
		puts "Invalid email_status type for company #{company}"
		return false
	end

	return true
end

# Returns true if the given user object has all required fields with the correct types
def validate_user(user)
	field_types = [
		['id', Integer],
		['first_name', String],
		['last_name', String],
		['email', String],
		['company_id', Integer],
		['tokens', Integer]
	]

	field_types.each do |field_type|
		field = field_type[0]
		if !user.key?(field)
			STDERR.puts "Missing field #{field} for user #{user}"
			return false
		end

		if user[field].class != field_type[1]
			puts "Company field #{field} incorrect type for user #{user}"
			return false
		end
	end
	
	# Do  a special check for boolean on email_status since I cant use the same logic above
	['email_status', 'active_status'].each do |field|
		if !user.key?(field) 
			puts "Missing #{field} field for user #{user}"
			return false
		end
		if ![true, false].include? user[field]
			puts "Invalid #{field} type for user #{user}"
			return false
		end
	end

	return true
end

# Appends output_data with a title and the user information if the users array is not empty
def add_users_to_output(output_data, title, users)
	output_data.append("\t#{title}:")
	users.each do |user|
		output_data.append("\t\t#{user['last_name']}, #{user['first_name']}, #{user['email']}")
		output_data.append("\t\t  Previous Token Balance, #{user['tokens']}")
		output_data.append("\t\t  New Token Balance #{user['new_tokens']}")
	end
end

# Returns an array of output data lines that should be written to the file
def get_output_data companies
	# when an empty string so we have an empty line at the start like the example
	output_data = [""]
	companies.each do |company|
		# Skip the company if there are no active users
		if company['users_emailed'].empty? && company['users_not_emailed'].empty?
			next
		end
		output_data.append("\tCompany Id: #{company['id']}")
		output_data.append("\tCompany Name: #{company['name']}")

		add_users_to_output output_data, "Users Emailed", company['users_emailed']
		add_users_to_output output_data, "Users Not Emailed", company['users_not_emailed']

		output_data.append("\t\tTotal amount of top ups for #{company['name']}: #{company['total_top_up']}")
		output_data.append("")
	end
	return output_data
end

# Runs the main program
def run
	users_data, companies_data = read_files

	# Store the companies in a map so we can quickly access them and add users
	company_map = {}
	companies_data.each do |company|
		# Skip the company if it doesnt pass validation
		if !validate_company company
			puts "Skipping invalid company #{company}"
			next
		end
		
		# Log a warning and skip the company if it already exists
		if company_map.key?(company['id'])
			puts "Company id already exists, skipping #{company}"
			next
		end

		company_map[company['id']] = company
		# Setup an empty array of users
		company_map[company['id']]['users_emailed'] = []
		company_map[company['id']]['users_not_emailed'] = []
		company_map[company['id']]['total_top_up'] = 0
	end

	if company_map.empty?
		puts "No companies found in companies file"
		return
	end

	# For each user find is associated company and add that user to the list of users
	users_data.each do |user|
		if !validate_user user
			puts "Skipping invalid user #{user}"
			next
		end

		# Skip the user if they are not active
		if !user['active_status']
			next
		end

		company = company_map[user['company_id']]

		# If the company doesnt exist then skip this user
		if !company_map.key?(user['company_id'])
			puts "Could not find company for #{user}"
			next
		end

		# Top up the users tokens and the company total top up
		user['new_tokens'] = user['tokens'] + company['top_up']
		company['total_top_up'] += company['top_up']

		# Append the user to the emailed or not list
		if company['email_status'] && user['email_status']
			company['users_emailed'].append(user)
		else
			company['users_not_emailed'].append(user)
		end
	end

	# Sort the the users in each company by last name and then put them in an array so we can sort them
	companies = []
	company_map.map do |id, company| 

		company['users_emailed'] = company['users_emailed'].sort_by { |user| user['last_name']}
		company['users_not_emailed'] = company['users_not_emailed'].sort_by { |user| user['last_name']}
		companies.append(company)
	end

	# Sort the companies by ID
	companies = companies.sort_by { |company| company['id']}

	# Create the output data
	output_data = get_output_data companies

	# Write output to output.txt
	File.open('output.txt', 'w') do |file|
	  file.puts output_data
	end
end

# Run the program by default when executing this file
main
