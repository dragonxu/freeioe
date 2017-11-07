local dc = require 'skynet.datacenter'
local cjson = require 'cjson.safe'

return {
	get = function(self)
		if lwf.auth.user == 'Guest' then
			self:redirect('/user/login')
		else
			local devices = dc.get('DEVICES') or {}
			--print(cjson.encode(devices))
			lwf.render('device.html', {devices=devices, cjson=cjson})
		end
	end
}
