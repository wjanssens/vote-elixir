defmodule Vote do

	# evaluate the election
	# given ballots and the number of seats to elect, returns the election results
	def evaluate(ballots, seats) do
		# find the unique list of candidates from all the ballots
		candidates = ballots
		|> Enum.flat_map(fn b -> Map.keys(b) end)
		|> Enum.uniq

		IO.puts("candidates")
		IO.inspect(candidates)

		# create a result that has an empty entry for every candidate
		result = candidates
		|> Enum.reduce(%{}, fn c, acc -> Map.put(acc, c, %{ votes: 0 }) end)
		result = Map.put(result, :exhausted, %{ votes: 0 })

		# calculate the number of votes it takes to be elected
		quota = Float.floor((Enum.count(ballots) / (seats + 1)) + 1)

		evaluate(result, ballots, 1, seats, quota)
	end

	# recursively evaluate the rounds of the election
	# returns updated results
	def evaluate(result, ballots, round, seats, quota) do
		IO.puts("evaluate #{round}")
		IO.inspect(ballots)
		counts = ranked_votes(ballots)
		IO.puts("counts")
		IO.inspect(counts)

		result = distribute(counts, result, 1)
		IO.inspect(result)

		# find the candidate with the most votes
		max = Enum.max_by(counts, fn {_, v} -> v end)
		{candidate, _} = max

		{_,candidate_result} = Enum.find(result, fn {k, _} -> k == candidate end)
		IO.puts("candidate: #{candidate}, votes: #{candidate_result.votes}")

		result = if candidate_result.votes >= quota do
			# a candidate has been elected
			surplus = candidate_result.votes - quota
			IO.puts("votes #{candidate_result.votes} >= quota #{quota}; surplus #{surplus}")

			# update the result for the elected candidate
			candidate_result = candidate_result
			|> Map.put(:surplus, surplus)
			|> Map.put(:status, :elected)
			|> Map.put(:round, round)
			result = Map.put(result, candidate, candidate_result)
			IO.puts("result")
			IO.inspect(result)

			# find all the ballots that had the elected candidate as the first pick
			# so that their votes can be distributed
			electing_ballots = ballots
			|> Enum.filter(fn b ->
				b
				|> Enum.min_by(fn {_, v} -> v end, fn -> %{exhausted: 0} end)
				|> Tuple.to_list
				|> Enum.member?(candidate)
			end)

			IO.puts("electing ballots")
			IO.inspect(electing_ballots)

			# each second choice vote is distributed as a fraction of the surplus
			weight = surplus / Enum.count(electing_ballots)

			# distribute the surplus votes from the elected candidate to the next pick
			electing_ballots
			|> trim(candidate)
			|> ranked_votes()
			|> distribute(result, weight)
		else
			# a candidate must be excluded
			min = Enum.min_by(counts, fn {_, v} -> v end)
			{excluded_candidate, _} = min

			# update the result for the excluded candidate
			excluded_result = Enum.find(result, fn {k, _} -> k == excluded_candidate end)
			|> Map.put(:status, :excluded)
			|> Map.put(:round, round)
			result = Map.put(result, excluded_candidate, excluded_result)

			# find all the ballots that had the excluded candidate as the first pick
			# so that their votes can be distributed
			excluding_ballots = ballots
			|> Enum.filter(fn b ->
				b
				|> Enum.min_by(fn {_, v} -> v end, fn -> %{exhausted: 0} end)
				|> Tuple.to_list
				|> Enum.member?(excluded_candidate)
			end)

			# each second choice vote is distributed as a fraction of the excluded votes
			weight = 1 / Enum.count(excluding_ballots) # TODO this seems wrong

			# distribute the votes from the excluded candidate to the next pick
			excluding_ballots
			|> ranked_votes()
			|> distribute(result, weight)
		end

		IO.puts("result")
		IO.inspect(result)

		# count how many candidates have been elected so far
		elected = result
		|> Enum.filter(fn {_,v} -> Map.has_key?(v, :status) && v.status == :elected end)
		|> Enum.count

		if quota == elected do
			# election is over
			result
		else
			# recurse for the next round
			{candidate,_} = Enum.find(result, fn {_,v} -> Map.has_key?(v, :round) && v.round == round end)
			evaluate(result, trim(ballots, candidate), round + 1, seats, quota)
		end
	end

	# returns a set of ballots that exclude a candidate
	def trim(ballots, candidate) do
		IO.puts("trim #{candidate}")
		ballots
		|> Enum.map(fn b -> Map.drop(b, [candidate]) end)
		|> Enum.filter(fn b -> !Enum.empty?(b) end) # TODO should empty ballots be counted now or later as exhausted?
	end

	# returns a map of how many votes a candidates has obtained in this round
	def ranked_votes(ballots) do
		IO.puts("ranked_votes")
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

	# applies vote distribution to result
	def distribute(counts, result, fraction) do
		IO.puts("distribute #{fraction}")
		Enum.reduce(result, %{}, fn {rk, rv}, a ->
			# vote count for the current candidate
			{_,cv} = Enum.find(counts, {rk,0}, fn {ck,_} -> ck == rk end)
			# update result row for candidate
			Map.put(a, rk, Map.update(rv, :votes, 0, &(&1 + (fraction * cv))))
		end)
	end

end
