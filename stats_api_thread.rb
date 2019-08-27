require "digest/sha3"

class StatsApiThread < Thread
  attr_reader :stats

  CONTRACT_ADDR = "0x3A9FfF453d50D4Ac52A6890647b823379ba36B9E"
  DEFAULT_STATS = {}

  def initialize(every:, on_change: nil, parity:)
    @on_change = on_change
    @parity    = parity
    @stats     = DEFAULT_STATS
    super(every) do |every|
      loop do
        begin
          work
        rescue => e
          puts "ERROR", e, e.backtrace
        ensure
          sleep every
        end
      end
    end
  rescue => e
    puts "ERROR", e, e.backtrace
  end

  private

  def on_change(*val)
    @on_change.call(*val) if @on_change
  end

#  def hashrate(mining_target, spr)
#    hashrate = 2**256 / mining_target / spr
#  end

  def work
    puts "updating stats"

    s = @parity.batch_call({
      currentEthBlock:    ["eth_blockNumber", nil],
      name:               "name()",
      symbol:             "symbol()",
      decimals:           "decimals()",
      circulatingSupply:  "totalSupply()",
      heapTop:            "heapTop()",
#      tokensMinted:       "tokensMinted()"
#      ldps:               "latestDifficultyPeriodStarted()",
#      miningTarget:       "miningTarget()",
#      challengeNumber:    "challengeNumber()",
#      rewardEra:          "rewardEra()",
#      maxSupplyForEra:    "maxSupplyForEra()",
      tokensBurned:       "tokensBurned()"
#      circulatingSupply:  "tokensMinted()",
#      lastRewardTo:       "lastRewardTo()",
#      lastRewardAmount:   "lastRewardAmount()",
#      lrebn:              "lastRewardEthBlockNumber()",
#      epochCount:         "epochCount()",
#      maximumTarget:      "_MAXIMUM_TARGET()",
#      minimumTarget:      "_MINIMUM_TARGET()",
#      bpr:                "_BLOCKS_PER_READJUSTMENT()"

    }, contract_addr:     CONTRACT_ADDR)

#    difficulty = s[:maximumTarget] / s[:miningTarget]
#    rsr        = s[:epochCount] % 1024
#    ebsldp     = s[:currentEthBlock] - s[:ldps]
#    ssr        = ebsldp * 15.0
#    spr        = rsr > 0 ? ssr / rsr : 600
#    hr         = hashrate(s[:miningTarget], spr)
    dec_units  = 10**s[:decimals]

    stats = {
      apiVersion:                         "5.12",
      name:                               s[:name],
      symbol:                             s[:symbol],
      contractUrl:                        "https://etherscan.io/address/#{CONTRACT_ADDR}",
      contractAddress:                    CONTRACT_ADDR,
      decimals:                           dec_units,
      circulatingSupply:                  (s[:circulatingSupply] / dec_units.to_f).to_f,
      heapTop:                            "0x%040x" % s[:heapTop].to_i(16), (s[:heapTop] / dec_units.to_f).to_f,
#      difficulty:                         difficulty,
#      minimumTarget:                      s[:minimumTarget].to_s,
#      maximumTarget:                      s[:maximumTarget].to_s,
#      miningTarget:                       s[:miningTarget].to_s,
#      challengeNumber:                    s[:challengeNumber],
#      rewardEra:                          s[:rewardEra].to_s,
#      maxSupplyForEra:                    s[:maxSupplyForEra],
#      blocksPerReadjustment:              s[:bpr],
#      latestDifficultyPeriodStarted:      s[:ldps],
      tokensBurned:                       1010101 - (s[:circulatingSupply] / dec_units.to_f).to_f,
#      circulatingSupply:                  (s[:tokensMinted] / dec_units.to_f).to_i,
#      lastRewardTo:                       "0x%040x" % s[:lastRewardTo].to_i(16),
#      lastRewardAmount:                   (s[:lastRewardAmount] / dec_units.to_f).to_f,
#      lastRewardEthBlockNumber:           s[:lrebn],
      currentEthBlock:                    s[:currentEthBlock]
#      ethBlocksSinceLastDifficultyPeriod: ebsldp,
#      secondsPerWinner:                   spw
#      hashrateEstimate:                   hr,
#      hashrateEstimateDescription:        "%0.2f GH/s" % (hr * 1e-9),
#      rewardsSinceReadjustment:           rsr
    }

    changed = stats != @stats
    @stats = stats # atomic replace
    on_change @stats if changed

    puts "done updating stats"
  end
end

if $0 == __FILE__
  # for testing
  require "./parity_rpc"
  config = YAML::load_file("config.yml")
  parity = ParityRPC.new(url: config["provider"])
  sat = StatsApiThread.new(parity: parity, every: 10, on_change: Proc.new { puts sat.stats })
  sleep
end
