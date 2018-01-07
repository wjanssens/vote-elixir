defmodule Vote do

	# evaluate the election
	# given ballots and the number of seats to elect, returns the election results
	def evaluate(ballots, seats) do
		# find the unique list of candidates from all the ballots
		candidates = ballots
		|> Enum.flat_map(fn b -> Map.keys(b) end)
		|> Enum.uniq

		# create a result that has an empty entry for every candidate
		result = candidates
		|> Enum.reduce(%{}, fn c, acc -> Map.put(acc, c, %{ votes: 0 }) end)

		# perform the initial vote distribution
		result = distribute(ballots, result)
		#IO.inspect result

		# calculate the number of votes it takes to be elected
		quota = Float.floor((Enum.count(ballots) / (seats + 1)) + 1)

		evaluate(result, ballots, 1, 0, seats, quota)
	end

	# recursively evaluate the rounds of the election
	# returns updated results
	def evaluate(result, ballots, round, elected, seats, quota) do
		#IO.puts "round #{round}"
		#IO.inspect result
		if seats == elected do
			result
		else
			# find the candidate with the most votes
			{elected_candidate, elected_result} = result
			|> Enum.filter(fn {_,v} -> !Map.has_key?(v, :status) end)
			|> Enum.max_by(fn {_,v} -> v.votes end)

			if elected_result.votes >= quota do
				# candidate has enough votes to be elected
				#IO.puts "electing #{elected_candidate}"

				# determine how many votes need redistribution
				surplus = elected_result.votes - quota

				# update the result for the elected candidate
				elected_result = elected_result
				|> Map.put(:surplus, surplus)
				|> Map.put(:status, :elected)
				|> Map.put(:round, round)
				result = Map.put(result, elected_candidate, elected_result)

				# distribute all the second choice votes from the ballots that elected this candidate
				electing_ballots = used(ballots, elected_candidate)
				#IO.puts "weight =  #{surplus} / #{Enum.count(electing_ballots)}"
				#IO.inspect electing_ballots
				weight = surplus / Enum.count(electing_ballots)
				result = distribute(electing_ballots, result, elected_candidate, weight)

				# perform the next round using ballots that exclude the elected candidate
				next_ballots = trim(ballots, elected_candidate)
				evaluate(result, next_ballots, round + 1, elected + 1, seats, quota)
			else
				# a candidate must be excluded
				# find the candidate with the least votes
				{excluded_candidate, excluded_result} = result
				|> Enum.filter(fn {_,v} -> !Map.has_key?(v, :status) end)
				|> Enum.min_by(fn {_,v} -> v.votes end)

				#IO.puts "excluding #{excluded_candidate}"

				# update the result for the excluded candidate
				excluded_result = excluded_result
				|> Map.put(:status, :excluded)
				|> Map.put(:round, round)
				result = Map.put(result, excluded_candidate, excluded_result)

				# distribute all the second choice votes from the ballots that excluded this candidate
				excluding_ballots = used(ballots, excluded_candidate)
				#IO.puts "weight =  #{excluded_result.votes} / #{Enum.count(excluding_ballots)}"
				#IO.inspect excluding_ballots
				weight = excluded_result.votes / Enum.count(excluding_ballots)
				result = distribute(excluding_ballots, result, excluded_candidate, weight)

				# perform the next round using ballots that exclude the elected candidate
				next_ballots = trim(ballots, excluded_candidate)
				evaluate(result, next_ballots, round + 1, elected, seats, quota)
			end
		end
	end

	# returns a list of ballots that exclude all votes for a candidate
	def trim(ballots, candidate) do
		ballots
		|> Enum.map(fn b -> Map.drop(b, [candidate])
		end)
		|> Enum.filter(fn b -> !Enum.empty?(b) end)
	end

	# return a list of ballots that contributed to a candidates election or exclusion
	def used(ballots, candidate) do
		ballots
		|> Enum.filter(fn b ->
			b
			|> Enum.min_by(fn {_, v} -> v end, fn -> %{exhausted: 0} end)
			|> Tuple.to_list
			|> Enum.member?(candidate)
		end)
	end

	# returns a map of how many votes a candidates has obtained in this round
	def ranked_votes(ballots) do
		ballots
		|> Enum.map(fn b ->
		  b
			# vote with the lowest rank
			|> Enum.min_by(fn {_, v} -> v end, fn -> %{exhausted: 0} end)
			|> Tuple.to_list
			# candidate from the vote
			|> List.first
		end)
		# count the number of votes for each candidate
		|> Enum.reduce(%{}, fn c, a -> Map.update(a, c, 1, &(&1 + 1)) end)
	end

	# applies initial vote distribution to result for all candidates
	# returns updated results
	def distribute(ballots, result) do
		counts = ranked_votes(ballots)
		Enum.reduce(result, %{}, fn {rk, rv}, a ->
			# vote count for the current candidate
			cv = Map.get(counts, rk, 0)
			# update result row for candidate
			Map.put(a, rk, Map.update(rv, :votes, 0, &(&1 + cv)))
		end)
	end

	# applies subsequent vote distribution to result for the elected or excluded candidate
	# returns updated results
	def distribute(ballots, result, candidate, weight) do
		counts = ranked_votes(trim(ballots, candidate))
		#IO.puts "distributing #{candidate} weight #{weight}"
		#IO.inspect counts
		result = Enum.reduce(result, %{}, fn {rk, rv}, a ->
			# vote count for the current candidate
			count = Map.get(counts, rk, 0)
			# update result row for candidate
			Map.put(a, rk, Map.update(rv, :votes, 0, &(&1 + (weight * count))))
		end)

		# exhausted count
		ev = Map.get(counts, :exhausted, 0)
		# result row for the current candidate
		rv = Map.get(result, candidate, 0)
		Map.put(result, candidate, Map.put(rv, :exhausted, ev))
	end

end
