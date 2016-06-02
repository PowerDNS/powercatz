#!/usr/bin/env lua-5.1

local http = require'socket.http'
local ltn12 = require'ltn12'
local json = require 'cjson'

function api(r)
	local t = {}
	r.sink = ltn12.sink.table(t)
	r.url = 'http://127.0.0.1:8081/api/v1/servers/localhost'..r.url
	r.headers = {['X-API-Key'] = 'xxx', ['Content-type'] = 'application/x-www-form-urlencoded'}
	if r.body then
		r.source = ltn12.source.string(r.body)
		r.headers['Content-Length'] = #r.body
		r.body = nil
	end
	local respt = http.request(r)
	return table.concat(t)
end

assert(#arg == 3)
local catzone, account, defaultmaster = unpack(arg)

local j = api{url='/zones/'..catzone}
local d = json.decode(j)
-- print(json.encode(d.rrsets))
local goalset = {}

for i,rec in ipairs(d.rrsets) do
	if rec.type == 'PTR' then

		print("Processing PTR "..rec.name)
		print("Record count is "..#rec.records)
		assert(#rec.records == 1)
		local zonename = rec.records[1].content
		print("Zone name is "..zonename)
		goalset[zonename] = 1
	end
end

print("Done reading catalog zone, desired zone list:")
for k,v in pairs(goalset) do
	print("- "..k)
end

local j = api{url='/zones'}
local d = json.decode(j)
local haveset = {}

for i, v in ipairs(d) do
	local zonename = v.name
	if v.account == account then
		haveset[zonename] = v.id
	end
end

print("Done reading current database, current zone list:")
for k,v in pairs(haveset) do
	print("- "..k)
end

print("Looking for zones to add")
for k,v in pairs(goalset) do
	if not haveset[k] then
		print ("Adding zone "..k)
		local req = json.encode{
			name=k,
			kind='slave',
			masters={defaultmaster},
			account=account
		}
		print(api{url='/zones', method='POST', body=req})
	end
end

print("Looking for zones to delete")
for k,v in pairs(haveset) do
	if not goalset[k] then
		print ("Deleting zone "..k.. " with id ["..v.."]")
		print(api{url='/zones/'..v, method='DELETE'})
	end
end