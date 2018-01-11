defmodule Vote do

	@moduledoc """
	Provides STV, IRV, Plurality, and Approval voting algotithms.

	All the algorithms take a list of ballots in the form:
	```
	[
	  %{"a" => 1, "b" => 2, ...},
	  %{"c" => 1, "d" => 2, ...},
	  ...
	]
	```
	and return results in the form:
	```
	%{
	  "a" => %{round: 1, status: :elected, votes: 40.0, surplus: 20.0, exhausted: 0},
	  "b" => %{round: 2, status: :excluded, votes: 8.0, exhausted: 0},
	  "c" => %{round: 3, status: :elected, votes: 20.0, surplus: 0.0, exhausted: 0},
	  "d" => %{votes: 17.0}
	}
	```
	"""


	@doc """
	Evaluates ballots according the traditional First-Past-The-Post algorithm.
	Ballots must contain exactly one vote, or they will be considered spoiled.
	This is the best choice when choosing between two candidates.
	"""
	def plurality(ballots) do
		candidates = ballots
		|> Stream.flat_map(fn b -> Map.keys(b) end)
		|> Stream.uniq

		# create a result that has an empty entry for every candidate
		result = candidates
		|> Enum.reduce(%{}, fn c, acc -> Map.put(acc, c, %{ votes: 0 }) end)

		result = distribute(ranked_votes(spoil_plurality(ballots)), result)

		{elected_candidate, elected_result} = result
		|> Enum.max_by(fn {_,v} -> v.votes end)

		elected_result = elected_result
		|> Map.put(:status, :elected)

		Map.put(result, elected_candidate, elected_result)
	end

	@doc """
	Evaluates ballots according the simplistic approval method.
	Ballots must contain any number of votes, all of which are considered equal.
	This is the best choice for polls like deciding what restaurant to go to.
	"""
	def approval(ballots, seats) do
		candidates = ballots
		|> Stream.flat_map(fn b -> Map.keys(b) end)
		|> Stream.uniq

		# create a result that has an empty entry for every candidate
		result = candidates
		|> Enum.reduce(%{}, fn c, acc -> Map.put(acc, c, %{ votes: 0 }) end)

		result = distribute(approval_votes(spoil_approval(ballots, candidates)), result)

		1..seats
		|> Enum.reduce(result, fn _, a ->
			{elected_candidate, elected_result} = a
			|> Stream.filter(fn {_,v} -> !Map.has_key?(v, :status) end)
			|> Enum.max_by(fn {_,v} -> v.votes end)

			elected_result = elected_result
			|> Map.put(:status, :elected)

			Map.put(a, elected_candidate, elected_result)
		end)
	end

	@doc """
	Evaluates ballots according the Instant Runoff method.
	Ballots must contain ranked votes.
	This is the best choice for electing a single candidate.
	"""
	def irv(ballots) do
		stv(ballots, 1)
	end

	@doc """
	Evaluates ballots according the Single Tranferrable Vote method.
	Ballots must contain ranked votes.
	This is the best choice for electing a group of candidates.
	"""
	def stv(ballots, seats) do
		# find the unique list of candidates from all the ballots
		candidates = ballots
		|> Stream.flat_map(fn b -> Map.keys(b) end)
		|> Stream.uniq

		# create a result that has an empty entry for every candidate
		result = candidates
		|> Enum.reduce(%{}, fn c, acc -> Map.put(acc, c, %{ votes: 0 }) end)

		ballots = spoil_ranked(ballots, candidates)

		# perform the initial vote distribution
		result = distribute(ranked_votes(ballots), result)
		#IO.inspect result

		# calculate the number of votes it takes to be elected
		quota = Float.floor((Enum.count(ballots) / (seats + 1)) + 1)

		stv(result, ballots, 1, 0, seats, quota)
	end

	# Recursively evaluate the subsequent rounds of STV.
	# Returns updated results.
	defp stv(result, ballots, round, elected, seats, quota) do
		#IO.puts "round #{round}"
		#IO.inspect result
		if seats == elected do
			result
		else
			# find the candidate with the most votes
			{elected_candidate, elected_result} = result
			|> Stream.filter(fn {_,v} -> !Map.has_key?(v, :status) end)
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
				stv(result, next_ballots, round + 1, elected + 1, seats, quota)
			else
				# a candidate must be excluded
				# find the candidate with the least votes
				{excluded_candidate, excluded_result} = result
				|> Stream.filter(fn {_,v} -> !Map.has_key?(v, :status) end)
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
				stv(result, next_ballots, round + 1, elected, seats, quota)
			end
		end
	end

	def parse_blt(stream) do
		# https://www.opavote.com/help/overview#blt-file-format

		# file consists of the following lines
		# :initial    1 line     <number of candidates c> <number of seats s>
		# :ballot     0~1 line   <the candidates that have withdrawn>+
		# :ballot     1~n lines  a ballot (see format below)
		# :ballot     1 line     0 (end of ballots marker)
		# :candidate  c lines    "<name of candidate>"
		# :candidate  1 line     "<name of election>"

		# each ballot has the format
		# <weight> <candidate> <candidate> ...0
		# weight can be used to group identical ballots
		# candidate is the integer id of the candidate (i.e. 1,2,3)
		# candidate may be a - to indicate a skipped vote
		# two candidates may be joined with = to indicate the have equal rank

		Enum.reduce(stream, %{state: :initial}, fn line, a ->
			[data | _] = String.split line, "#", parts: 2
			data = String.trim data

			cond do
				data == "" -> # comment only line
					a
				a.state == :initial -> # first line
					[c, s] = String.split data, " "
					{candidates, _} = Integer.parse c
					{seats, _} = Integer.parse s
					a
					|> Map.put(:remaining, candidates)
					|> Map.put(:seats, seats)
					|> Map.put(:state, :ballot)
					|> Map.put(:ballots, [])
					|> Map.put(:candidates, [])
				a.state == :ballot && data == "0" -> # end of ballots marker line
					Map.put a, :state, :candidate
				a.state == :ballot && String.starts_with?(data, "-") -> # withdrawn candidates line
					withdrawn = Regex.scan(~r/(-\d+)+/, data)
					|> Enum.map(fn [match, _] ->
						{c, _} = Integer.parse match
						-c
					end)
					Map.put a, :withdrawn, withdrawn
				a.state == :ballot -> # ballot line
					[weight | candidates] = String.split data, " "
					{weight, _} = Integer.parse(weight)
					ballot = Enum.reduce(candidates, {1, %{}}, fn term, {rank, ballot} ->
						case term do
							"0" ->
								ballot # end of ballot marker
							"-" ->
								{ rank + 1, ballot } # undervote marker
							_ ->
								{ rank + 1,
									Enum.reduce(String.split(term, "="), ballot, fn c, a ->
										{c, _} = Integer.parse(c)
										Map.put a, c, rank
									end)
								}
						end
					end)
					Map.update!(a, :ballots, fn ballots ->
						Enum.reduce(1..weight, ballots, fn _, a ->
							[ballot] ++ a
						end)
					end)
				a.state == :candidate && a.remaining == 0 ->
					a
					|> Map.put(:title, String.replace(String.trim(data, "\""), "\\", ""))
					|> Map.delete(:remaining)
					|> Map.delete(:state)
				a.state == :candidate ->
					a
					|> Map.update(:candidates, [], fn candidates ->
						candidates ++ [String.replace(String.trim(data, "\""), "\\", "")]
					end)
					|> Map.update!(:remaining, &(&1 - 1))
				true ->
					a
			end # cond
		end) # reduce
	end

	# Returns a list of ballots that exclude all votes for a candidate
	defp trim(ballots, candidate) do
		ballots
		|> Stream.map(fn b -> Map.drop(b, [candidate]) end)
	end

	# Returns a list of ballots that contributed to a candidates election or exclusion
	defp used(ballots, candidate) do
		ballots
		|> Stream.filter(fn b ->
			b
			|> Enum.min_by(fn {_, v} -> v end, fn -> {:exhausted, 0} end)
			|> Tuple.to_list
			|> Enum.member?(candidate)
		end)
	end

	# Filters spoiled ballots
	defp spoil_approval(ballots, candidates) do
		count = Enum.count(candidates)
		ballots
		|> Stream.filter(fn b -> !Enum.empty?(b) end) # have to vote for someone
		|> Stream.filter(fn b -> Enum.count(b) < count end) # can't vote for everyone
	end

	# Filters spoiled ballots
	defp spoil_plurality(ballots) do
		ballots
		|> Stream.filter(fn b -> Enum.count(b) == 1 end) # have to vote for exactly one candidate
	end

	# Filters spoiled ballots
	defp spoil_ranked(ballots, candidates) do
		# count = Enum.count(candidates)
		ballots
		|> Stream.filter(fn b ->
			v = Map.values(b)
			{min, max} = Enum.min_max(v)
			min == 1 && max == Enum.count(Enum.uniq(v)) # must be a contiguous range of rankings
		end)
	end

	# Returns a map of how many approvals a candidate has obtained
	defp approval_votes(ballots) do
		ballots
		|> Stream.flat_map(fn b -> Map.keys(b) end)
		# count the number of votes for each candidate
		|> Enum.reduce(%{}, fn c, a -> Map.update(a, c, 1, &(&1 + 1)) end)
	end

	# Returns a map of how many votes a candidates has obtained in this round
	defp ranked_votes(ballots) do
		ballots
		|> Stream.map(fn b ->
		  b
			# vote with the lowest rank
			|> Enum.min_by(fn {_, v} -> v end, fn -> {:exhausted, 0} end)
			|> Tuple.to_list
			# candidate from the vote
			|> List.first
		end)
		# count the number of votes for each candidate
		|> Enum.reduce(%{}, fn c, a -> Map.update(a, c, 1, &(&1 + 1)) end)
	end

	# Applies initial vote distribution to result for all candidates.
	# Returns updated results.
	defp distribute(counts, result) do
		Enum.reduce(result, %{}, fn {rk, rv}, a ->
			# vote count for the current candidate
			cv = Map.get(counts, rk, 0)
			# update result row for candidate
			Map.put(a, rk, Map.update(rv, :votes, 0, &(&1 + cv)))
		end)
	end

	# Applies subsequent vote distribution to result for the elected or excluded candidate
	# Returns updated results.
	defp distribute(ballots, result, candidate, weight) do
		counts = ranked_votes(trim(ballots, candidate))
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
		Map.put(result, candidate, Map.put(rv, :exhausted, weight * ev))
	end

end
