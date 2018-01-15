defmodule VoteTest do
  use ExUnit.Case
  doctest Vote

  test "stv" do
    # see https://en.wikipedia.org/wiki/Counting_single_transferable_votes

    ballots =
      Enum.concat([
        Enum.map(1..16, fn _ -> %{"a" => 1, "b" => 2, "c" => 3, "d" => 4} end),
        Enum.map(1..24, fn _ -> %{"a" => 1, "b" => 3, "c" => 2, "d" => 4} end),
        Enum.map(1..17, fn _ -> %{"a" => 2, "b" => 3, "c" => 4, "d" => 1} end)
      ])

    result = Vote.eval(ballots, 2)
    # IO.inspect result

    c = Map.get(result, "a")
    assert c.round == 1
    assert c.votes == 40
    assert c.surplus == 20
    assert c.status == :elected

    c = Map.get(result, "b")
    assert c.round == 2
    assert c.votes == 8
    assert c.status == :excluded

    c = Map.get(result, "c")
    assert c.round == 3
    assert c.votes == 20
    assert c.surplus == 0
    assert c.status == :elected

    c = Map.get(result, "d")
    assert c.votes == 17
  end

  test "animal_stv_1" do
    # see https://www.youtube.com/watch?v=l8XOZJkozfI

    ballots =
      Enum.concat([
        Enum.map(1..05, fn _ -> %{"tarsier" => 1, "gorilla" => 2} end),
        Enum.map(1..28, fn _ -> %{"gorilla" => 1} end),
        Enum.map(1..33, fn _ -> %{"monkey" => 1} end),
        Enum.map(1..21, fn _ -> %{"tiger" => 1} end),
        Enum.map(1..13, fn _ -> %{"lynx" => 1, "tiger" => 2} end)
      ])

    # run the election with Droop quota
    result = Vote.eval(ballots, 3)

    c = Map.get(result, "monkey")
    assert c.round == 1
    assert c.votes == 33
    assert c.surplus == 7
    assert c.status == :elected

    c = Map.get(result, "gorilla")
    assert c.round == 2
    assert c.votes == 28
    assert c.surplus == 2
    assert c.status == :elected

    c = Map.get(result, "tarsier")
    assert c.round == 3
    assert c.votes == 5
    assert c.status == :excluded

    c = Map.get(result, "lynx")
    assert c.round == 4
    assert c.votes == 13
    assert c.status == :excluded

    c = Map.get(result, "tiger")
    assert c.round == 5
    assert c.votes == 34
    assert c.surplus == 8
    assert c.status == :elected

    # run the election with Hare quota
    result = Vote.eval(ballots, 3, quota: :hare)

    c = Map.get(result, "monkey")
    assert c.round == 1
    assert c.votes == 33
    assert c.surplus == 0
    assert c.status == :elected

    c = Map.get(result, "tarsier")
    assert c.round == 2
    assert c.votes == 5
    assert c.status == :excluded

    c = Map.get(result, "gorilla")
    assert c.round == 3
    assert c.votes == 33
    assert c.surplus == 0
    assert c.status == :elected

    c = Map.get(result, "lynx")
    assert c.round == 4
    assert c.votes == 13
    assert c.status == :excluded

    c = Map.get(result, "tiger")
    assert c.round == 5
    assert c.votes == 34
    assert c.surplus == 1
    assert c.status == :elected
  end

  test "animal_stv_2" do
    # see https://www.youtube.com/watch?v=l8XOZJkozfI

    ballots =
      Enum.concat([
        Enum.map(1..65, fn _ -> %{"white tiger" => 1, "tiger" => 2} end),
        Enum.map(1..01, fn _ -> %{"tiger" => 1, "white tiger" => 2} end),
        Enum.map(1..16, fn _ -> %{"silverback" => 1, "gorilla" => 2} end),
        Enum.map(1..18, fn _ -> %{"gorilla" => 1, "silverback" => 2} end)
      ])

    # run the election with Droop quota
    result = Vote.eval(ballots, 3)

    c = Map.get(result, "white tiger")
    assert c.round == 1
    assert c.votes == 65
    assert c.surplus == 39
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "tiger")
    assert c.round == 2
    assert c.votes == 40
    assert c.surplus == 14
    # there were no third choices so the 14 surplus are exhausted
    assert c.exhausted == 14
    assert c.status == :elected

    c = Map.get(result, "silverback")
    assert c.round == 3
    assert c.votes == 16
    assert c.exhausted == 0
    assert c.status == :excluded

    c = Map.get(result, "gorilla")
    assert c.round == 4
    assert c.votes == 34
    assert c.surplus == 8
    assert c.status == :elected

    # run the election with Hare quota
    result = Vote.eval(ballots, 3, quota: :hare)

    c = Map.get(result, "white tiger")
    assert c.round == 1
    assert c.votes == 65
    assert c.surplus == 32
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "tiger")
    assert c.round == 2
    assert c.votes == 33
    assert c.surplus == 0
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "silverback")
    assert c.round == 3
    assert c.votes == 16
    assert c.exhausted == 0
    assert c.status == :excluded

    c = Map.get(result, "gorilla")
    assert c.round == 4
    assert c.votes == 34
    assert c.surplus == 1
    assert c.status == :elected
  end

  test "animal_stv_3" do
    # see https://www.youtube.com/watch?v=Ac9070OIMUg

    ballots =
      Enum.concat([
        Enum.map(1..05, fn _ -> %{"tarsier" => 1, "silverback" => 2} end),
        Enum.map(1..10, fn _ -> %{"gorilla" => 1, "tarsier" => 2, "silverback" => 3} end),
        Enum.map(1..22, fn _ -> %{"gorilla" => 1, "silverback" => 2} end),
        Enum.map(1..03, fn _ -> %{"silverback" => 1} end),
        Enum.map(1..33, fn _ -> %{"owl" => 1, "turtle" => 2} end),
        Enum.map(1..01, fn _ -> %{"turtle" => 1} end),
        Enum.map(1..01, fn _ -> %{"snake" => 1, "turtle" => 2} end),
        Enum.map(1..16, fn _ -> %{"tiger" => 1} end),
        Enum.map(1..04, fn _ -> %{"lynx" => 1, "tiger" => 2} end),
        Enum.map(1..02, fn _ -> %{"jackalope" => 1} end),
        Enum.map(1..02, fn _ -> %{"buffalo" => 1, "jackalope" => 2} end),
        Enum.map(1..01, fn _ -> %{"buffalo" => 1, "jackalope" => 2, "turtle" => 3} end)
      ])

    # this is a really interesting comparison of Hare vs Droop quota
    # in both cases the same candidates are elected, but in completely different
    # rounds and with Turtle having a clear win with Droop but only winning by
    # default with Hare

    # run the election with Droop quota
    result = Vote.eval(ballots, 5)

    c = Map.get(result, "owl")
    assert c.round == 1
    assert c.votes == 33
    assert c.surplus == 16
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "gorilla")
    assert c.round == 2
    assert c.votes == 32
    assert c.surplus == 15
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "turtle")
    assert c.round == 3
    assert c.votes == 17
    assert c.surplus == 0
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "snake")
    assert c.round == 4
    assert c.votes == 1
    assert c.exhausted == 1
    assert c.status == :excluded

    c = Map.get(result, "jackalope")
    assert c.round == 5
    assert c.votes == 2
    assert c.exhausted == 2
    assert c.status == :excluded

    c = Map.get(result, "buffalo")
    assert c.round == 6
    assert c.votes == 3
    assert c.exhausted == 3
    assert c.status == :excluded

    c = Map.get(result, "lynx")
    assert c.round == 7
    assert c.votes == 4
    assert c.exhausted == 0
    assert c.status == :excluded

    c = Map.get(result, "tiger")
    assert c.round == 8
    assert c.votes == 20
    assert c.surplus == 3
    assert c.exhausted == 3
    assert c.status == :elected

    c = Map.get(result, "tarsier")
    assert c.round == 9
    assert c.votes == 9.6875
    assert c.exhausted == 0
    assert c.status == :excluded

    c = Map.get(result, "silverback")
    assert c.round == 10
    assert c.votes == 23
    assert c.surplus == 6
    assert c.status == :elected

    # run the election with Hare quota
    result = Vote.eval(ballots, 5, quota: :hare)

    c = Map.get(result, "owl")
    assert c.round == 1
    assert c.votes == 33
    assert c.surplus == 13
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "gorilla")
    assert c.round == 2
    assert c.votes == 32
    assert c.surplus == 12
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "snake")
    assert c.round == 3
    assert c.votes == 1
    assert c.exhausted == 0
    assert c.status == :excluded

    c = Map.get(result, "jackalope")
    assert c.round == 4
    assert c.votes == 2
    assert c.exhausted == 2
    assert c.status == :excluded

    c = Map.get(result, "buffalo")
    assert c.round == 5
    assert c.votes == 3
    assert c.exhausted == 2
    assert c.status == :excluded

    c = Map.get(result, "lynx")
    assert c.round == 6
    assert c.votes == 4
    assert c.exhausted == 0
    assert c.status == :excluded

    c = Map.get(result, "tiger")
    assert c.round == 7
    assert c.votes == 20
    assert c.surplus == 0
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "tarsier")
    assert c.round == 8
    assert c.votes == 8.75
    assert c.exhausted == 0
    assert c.status == :excluded

    c = Map.get(result, "silverback")
    assert c.round == 9
    assert c.votes == 20
    assert c.surplus == 0
    assert c.exhausted == 0
    assert c.status == :elected

    c = Map.get(result, "turtle")
    assert c.round == 10
    assert c.votes == 16
    assert c.surplus == -4
    assert c.status == :elected
  end

  test "animal_av" do
    # see https://www.youtube.com/watch?v=3Y3jE3B8HsE

    ballots =
      Enum.concat([
        Enum.map(1..05, fn _ -> %{"turtle" => 1, "owl" => 2} end),
        Enum.map(1..25, fn _ -> %{"gorilla" => 1, "owl" => 2} end),
        Enum.map(1..25, fn _ -> %{"owl" => 1} end),
        Enum.map(1..30, fn _ -> %{"leopard" => 1} end),
        Enum.map(1..15, fn _ -> %{"tiger" => 1, "leopard" => 2} end)
      ])

    result = Vote.eval(ballots, 1)

    c = Map.get(result, "turtle")
    assert c.round == 1
    assert c.votes == 5
    assert c.status == :excluded

    c = Map.get(result, "tiger")
    assert c.round == 2
    assert c.votes == 15
    assert c.status == :excluded

    c = Map.get(result, "gorilla")
    assert c.round == 3
    assert c.votes == 25
    assert c.status == :excluded

    c = Map.get(result, "owl")
    assert c.round == 4
    assert c.votes == 55
    assert c.status == :elected

    c = Map.get(result, "leopard")
    assert c.votes == 45
  end

  test "plurality" do
    ballots =
      Enum.concat([
        Enum.map(1..16, fn _ -> %{"a" => 1} end),
        Enum.map(1..24, fn _ -> %{"b" => 1} end),
        Enum.map(1..11, fn _ -> %{"c" => 1} end),
        Enum.map(1..17, fn _ -> %{"d" => 1} end)
      ])

    result = Vote.eval(ballots, 1)
    # IO.inspect result

    c = Map.get(result, "c")
    assert c.round == 1
    assert c.votes == 11
    assert c.exhausted == 11
    assert c.status == :excluded

    c = Map.get(result, "a")
    assert c.round == 2
    assert c.votes == 16
    assert c.exhausted == 16
    assert c.status == :excluded

    c = Map.get(result, "d")
    assert c.round == 3
    assert c.votes == 17
    assert c.exhausted == 17
    assert c.status == :excluded

    c = Map.get(result, "b")
    assert c.round == 4
    assert c.votes == 24
    assert c.status == :elected
  end

  test "parse blt" do
    # see https://www.opavote.com/help/overview#blt-file-format

    file = """
    4 2          # Four candidates are competing for two seats
    -2           # Bob has withdrawn
    1 4 1 3 2 0  # First ballot
    1 3 4 1 2 0  # Chuck first, Amy second, Diane third, Bob fourth
    1 2 4 1 0    # Bob first, Amy second, Diane third
    1 4 3 0      # Amy first, Chuck second
    6 4 3 0      # Amy first, Chuck second with a weight of 6
    1 0          # An empty ballot
    1 2 - 3 0    # Bob first, no one second, Chuck third
    1 2=3 1 0    # Bob and Chuck first, Diane second
    1 2 3 4 1 0  # Last ballot
    0            # End of ballots marker
    "Diane"      # Candidate 1
    "Bob"        # Candidate 2
    "Chuck"      # Candidate 3
    "Amy"        # Candidate 4
    "Gardening Club Election"  # Title
    """

    lines = String.split(file, "\n")
    election = Vote.parse_blt(lines)

    # IO.inspect(election)

    assert election.title == "Gardening Club Election"
    assert election.candidates == ["Diane", "Bob", "Chuck", "Amy"]
    assert election.seats == 2
    assert election.withdrawn == [2]
    assert Enum.count(election.ballots) == 14

    result = Vote.eval(election.ballots, election.seats) |> Vote.rekey(election.candidates)

    # IO.inspect(result)

    assert Map.get(result, "Amy").round == 1
    assert Map.get(result, "Diane").round == 2
    assert Map.get(result, "Chuck").round == 3
    assert Map.get(result, "Bob").round == 4
  end
end
