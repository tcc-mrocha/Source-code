-- telnet - servidor - debug - serial port - remotamente
s = net.createServer(net.TCP)

s:listen(2323, 
	function(c)
		print("\nServidor telnet rodando...")
		
		con_std = c
		
		function s_output(str)
			if(con_std~=nil) then 
				con_std:send(str) 
			end
		end
		
		node.output(s_output, 1)   -- re-direct output to function s_ouput.
		
		c:on("disconnection",
			function(c)
				con_std = nil
				node.output(nil)        -- un-regist the redirect output function, output goes to serial
			end
		)  
		
	end
)



