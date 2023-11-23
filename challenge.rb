require 'json'


# Appends output_data with a title and the user information if the users array is not empty
def add_users_to_output(output_data, title, users)
	output_data.append("\t#{title}:")
	users.each do |user|
		output_data.append("\t\t#{user['last_name']}, #{user['first_name']}, #{user['email']}")
		output_data.append("\t\t  Previous Token Balance, #{user['tokens']}")
		output_data.append("\t\t  New Token Balance #{user['new_tokens']}")
	end
end

def main
	begin
		run
	rescue => e
		puts "Error running challenge.rb:"
		raise
	else
		puts "challenge.rb Complete"
	end
end

def run
	# Read JSON files
	users_data = JSON.parse(File.read('users.json'))
	companies_data = JSON.parse(File.read('companies.json'))

	# Store the companies in a map so we can quickly access them and add users
	company_map = {}
	companies_data.each do |company|
		company_map[company['id']] = company
		# Setup an empty array of users
		company_map[company['id']]['users_emailed'] = []
		company_map[company['id']]['users_not_emailed'] = []
		company_map[company['id']]['total_top_up'] = 0
	end

	# For each user find is associated company and add that user to the list of users
	users_data.each do |user|
		user_comp = user['company_id']
		company = company_map[user['company_id']]

		# Skip the user if they are not active
		if !user['active_status']
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

	# Write output to output.txt
	File.open('output.txt', 'w') do |file|
	  file.puts output_data
	end
end

main
