require "sinatra"
require "./parity_rpc"
require "./stats_api_thread"

config = YAML::load_file("config.yml")
parity = ParityRPC.new(url: config["provider"])
set :port, config["port"]

# keep rendered JSON in a cache. update as necessary.
$stats_json = "{}"
stats_api_thread = StatsApiThread.new(
  parity:     parity,
  every:      config["every"],
  on_change:  Proc.new { |stats| $stats_json = stats.to_json }
)

get "/stats.json" do
  content_type :json
  response.headers["Access-Control-Allow-Origin"] = "*"
  $stats_json
end
