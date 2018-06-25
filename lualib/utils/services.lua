---
-- Services Control Utils 
--
local lfs = require 'lfs'
local skynet = require 'skynet'
local class = require 'middleclass'
local sysinfo = require 'utils.sysinfo'
local pm = require 'utils.process_monitor'

local services = class("FREEIOE_SERVICES_CONTRL_API")

function services:initialize(name, cmd, args, options)
	assert(name and cmd)
	self._name = "ioe_"..name
	self._cmd = cmd
	if args then
		self._cmd = cmd .. ' ' .. table.concat(args, ' ')
	end

	self._pid = "/tmp/service_"..self._name..".pid"
	-- self._file = "/etc/init.d/"..self._name
	self._file = "/tmp/"..self._name

	local os_id = sysinfo.os_id()
	if string.lower(os_id) ~= 'openwrt' then
		self._pm = pm:new(name, cmd, args, options)
	end
	self._options = options or {}
end

local procd_file = [[
#!/bin/sh /etc/rc.common
START=99
USE_PROCD=1
start_service () {
	procd_open_instance
	procd_set_param command %s
	procd_set_param pidfile %s
	procd_set_param respawn
	procd_close_instance
}
]]

function services:create()
	if self._pm then
		return true
	end
	local s = string.format(procd_file, self._cmd, self._pid)
	if lfs.attributes(self._file, "mode") == file then
		return nil, "Service already exits"
	end

	local f, err = io.open(self._file, "w+")
	if not f then
		return nil, err
	end

	f:write(s)
	f:close()
	return os.execute("service "..self._name.." enable")
end

function services:cleanup()
	if self._pm then
		return self._pm:cleanup()
	end
end

function services:remove()
	if self._pm then
		return true
	end
	os.execute("service "..self._name.." disable")
	os.execute('rm -f '..self._file)
end

function services:__gc()
	self:stop()
	self:remove()
end

function services:start()
	if self._pm then
		return self._pm:start()
	end
	return os.execute("service "..self._name.." start")
end

function services:stop()
	if self._pm then
		return self._pm:stop()
	end
	return os.execute("service "..self._name.." stop")
end

function services:reload()
	if self._pm then
		return nil, "Not support"
	end
	return os.execute("service "..self._name.." reload")
end

function services:restart()
	if self._pm then
		return nil, "Not support"
	end
	return os.execute("service "..self._name.." restart")
end

function services:get_pid()
	if self._pm then
		return self._pm:get_pid()
	end
	local f, err = io.open(self._pid, 'r')
	if not f then
		return nil, 'pid file not found'..err
	end
	local id = f:read('*a')
	f:close()
	local pid = tonumber(id)
	if not pid then
		return nil, "pid file read error"
	end
	return pid
end

function services:status()
	if self._pm then
		return self._pm:status()
	end

	local pid, err = self:get_pid()
	if not pid then
		return nil, err
	end
	return os.execute('kill -0 '..pid)
end

return services