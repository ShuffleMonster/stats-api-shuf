require "httparty"
require "json"

class ParityRPCError < StandardError
end

# a custom JSONRPC interface to parity that does only what we need
class ParityRPC
  def initialize(opts)
    @id = 0
    @url = opts[:url]
    @method_cache = {}
  end

  def batch_call(calls, contract_addr: nil)
    batch(calls.collect do |name, method|
      if method.is_a?(String)
        [name, ["eth_call", [{to: contract_addr, data: solidity_signature(method)}, "latest"]]]
      else
        [name, method]
      end
    end.to_h)
  end

  private

  def batch(method_params)
    ids = {}
    rpc_calls = method_params.collect do |name, (method, params)|
      id = next_id
      ids[id] = name
      {method: method, params: params, id: id, jsonrpc: "2.0"}
    end
    body = rpc_calls.to_json
    headers = {"Content-Type" => "application/json"}
    r = HTTParty.post(@url, body: body, headers: headers, format: :plain)
    j = JSON.parse(r, symbolize_names: true)
    raise ParityRPCError.new(j[:error][:message]) if j.is_a?(Hash) && j[:error] # overall error for batch request
    decode(j.collect do |br|
      next if br[:error] # turn errors in to nils, not great
      [ids[br[:id]], br[:result]]
    end.compact.to_h)
  end

  DECODE_STRING = Set[:name, :symbol]
  DECODE_ADDR = Set[:heapTop]
  DECODE_UNIT = Set[:heapTop]
  NO_DECODE_HEX = Set[:heapTop]
  def decode(data)
    data.collect do |k, v|
      if v.is_a?(String)
        if DECODE_ADDR.include?(k)
          v = decode_addr(v)
        elsif DECODE_STRING.include?(k)
          v = decode_string(v)
        elsif !NO_DECODE_HEX.include?(k)
          v = v.to_i(16)
        end
      end
      [k, v]
    end.to_h
  end

  def solidity_signature(method)
    @method_cache[method] ||= "0x" + Digest::SHA3.hexdigest(method, 256)[0..7]
  end

  def next_id
    @id += 1
  end

  def decode_string(hex_repr)
    hex_repr = hex_repr[2..-1]
    _, length, data = hex_repr.scan(%r(.{64}))
    [data].pack("H*")[0...length.to_i(16)]
  end

  def decode_addr(hex_repr)
    "0x%040x" % hex_repr.to_i(16)
  end
end
