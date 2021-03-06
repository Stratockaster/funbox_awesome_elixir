install:
	mix deps.get && cd assets && npm install

server:
	elixir --sname fbae -S mix phx.server -e 'FunboxAwesomeElixir.Controller.update_data'

iex-server:
	iex --sname fbae -S mix phx.server -e 'FunboxAwesomeElixir.Controller.update_data'

iex:
	iex -S mix

server-attach:
	iex --sname remsh --remsh fbae
