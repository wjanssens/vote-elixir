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
		result = Map.put(result, :exhausted, %{ votes: 0 })

		# calculate the number of votes it takes to be elected
		quota = Float.floor((Enum.count(ballots) / (seats + 1)) + 1)

		evaluate(result, ballots, 1, 1, 0, seats, quota)
	end

	# recursively evaluate the rounds of the election
	# returns updated results
	def evaluate(result, ballots, round, weight, elected, seats, quota) do
		if seats == elected do
			result
		else
			counts = ranked_votes(ballots)

			result = distribute(counts, result, weight)

			# find the candidate with the most votes
			max = Enum.max_by(counts, fn {_, v} -> v end)
			{candidate, _} = max

			{_,candidate_result} = Enum.find(result, fn {k, _} -> k == candidate end)

			if candidate_result.votes >= quota do
				# a candidate has been elected
				surplus = candidate_result.votes - quota

				# update the result for the elected candidate
				candidate_result = candidate_result
				|> Map.put(:surplus, surplus)
				|> Map.put(:status, :elected)
				|> Map.put(:round, round)
				result = Map.put(result, candidate, candidate_result)

				# find all the ballots that had the elected candidate as the first pick
				# so that their votes can be distributed
				electing_ballots = contributing_ballots(ballots, candidate)

				# each second choice vote is distributed as a fraction of the surplus
				weight = weight * surplus / Enum.count(electing_ballots)

				# recurse for the next round
				next_ballots = trim(electing_ballots, candidate)
				evaluate(result, next_ballots, round + 1, weight, elected + 1, seats, quota)
			else
				# a candidate must be excluded
				min = Enum.min_by(counts, fn {_, v} -> v end)
				{excluded_candidate, _} = min

				# update the result for the excluded candidate
				{_,excluded_result} = Enum.find(result, fn {k, _} -> k == excluded_candidate end)
				excluded_result = excluded_result
				|> Map.put(:status, :excluded)
				|> Map.put(:round, round)
				result = Map.put(result, excluded_candidate, excluded_result)

				excluding_ballots = contributing_ballots(ballots, excluded_candidate)
				next_ballots = trim(excluding_ballots, excluded_candidate)

				evaluate(result, next_ballots, round + 1, weight, elected, seats, quota)
			end
		end
	end

	# returns a set of ballots that exclude a candidate
	def trim(ballots, candidate) do
		ballots
		|> Enum.map(fn b -> Map.drop(b, [candidate]) end)
		|> Enum.filter(fn b -> !Enum.empty?(b) end)
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

	def contributing_ballots(ballots, candidate) do
		ballots
		|> Enum.filter(fn b ->
			b
			|> Enum.min_by(fn {_, v} -> v end, fn -> %{exhausted: 0} end)
			|> Tuple.to_list
			|> Enum.member?(candidate)
		end)
	end

	# applies vote distribution to result
	def distribute(counts, result, fraction) do
		Enum.reduce(result, %{}, fn {rk, rv}, a ->
			# vote count for the current candidate
			{_,cv} = Enum.find(counts, {rk,0}, fn {ck,_} -> ck == rk end)
			# update result row for candidate
			Map.put(a, rk, Map.update(rv, :votes, 0, &(&1 + (fraction * cv))))
		end)
	end

end
