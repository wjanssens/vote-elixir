# Vote

Implements the Single Transferrable Vote algorithm

Takes a list of ballots in the form:
```
[
  %{"a" => 1, "b" => 2, ...},
  %{"c" => 1, "d" => 2, ...},
  ...
]
```

Returns a map of the results in the form:
```
%{
  "a" => %{exhausted: 0, round: 1, status: :elected, surplus: 20.0, votes: 40.0},
  "b" => %{exhausted: 0, round: 2, status: :excluded, votes: 8.0},
  "c" => %{exhausted: 0, round: 3, status: :elected, surplus: 0.0, votes: 20.0},
  "d" => %{votes: 17.0}
}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `vote` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vote, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/vote](https://hexdocs.pm/vote).
