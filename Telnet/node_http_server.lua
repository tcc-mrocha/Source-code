-- servidor http que mostra uma pagina com informacoes sobre o hardware do dispositivo
http_server = net.createServer(net.TCP)

-- servidor passa a ouvir na porta 80 (porta padrao http)
http_server:listen(80, 
    function(conn) -- funcao callback que responde apos uma conexao ser efetuada
        conn:on("receive", 
            function(conn, payload) -- apos conexao, responde com a pagina com os dados
                print(payload)
				pagina = '<!DOCTYPE html>' ..
				'<html>' ..
				'<head>' ..
				'<meta charset="utf-8"><meta http-equiv="refresh" content="60">' ..
				'<title>Informações do dispositivo' .. node_nome .. '</title>' ..
				'</head>' ..
				'<body>' ..
				'<div align="center"> <tb colspan="2"></tb><tb></tb><tb colspan="2"></tb><tb></tb>' ..
				'<table style="width: 60%"; border="2">' ..
				'<tbody>' ..
				'<tr>' ..
				'<td rowspan="1" colspan="4" style="text-align: center;">' ..
				'<h3><b>Informações do dispositivo - ' .. node_nome .. '</b></h3>'
				conn:send(pagina) -- envia fragmento da pagina
				pagina = '</td>' ..
				'</tr>' ..
				'<tr>' ..
				'<td style="text-align: center;" colspan="2">' ..
				'<h3>Hardware</h3>' ..
				'</td>' ..
				'<td colspan="2" style="text-align: center;">' ..
				'<h3>Wifi Settings</h3>' ..
				'</td>' ..
				'</tr>' ..
				'<tr>' ..
				'<td style="text-align: right; width: 20%;"><b>Major version</b></td>' ..
				'<td style="width: 30%;"> ' .. majorver .. '<br>' ..
				'</td>' ..
				'<td style="text-align: right; width: 20%;"><b>Endereço IP</b><br>' ..
				'</td>'
				conn:send(pagina)-- envia fragmento da pagina
				pagina =  '<td>' .. meu_ip .. '<br>' ..
				'</td>' ..
				'</tr>' ..
				'<tr>' ..
				'<td style="text-align: right;"><b>Minor version</b></td>' ..
				'<td> ' .. minorver .. '<br>' ..
				'</td>' ..
				'<td style="text-align: right;"><b>Endereço MAC</b><br>' ..
				'</td>' ..
				'<td> ' .. meu_mac .. '<br>' ..
				'</td>' ..
				'</tr>' ..
				'<tr>'
				conn:send(pagina)-- envia fragmento da pagina
				pagina =  '<td style="text-align: right;"><b>Dev. version</b></td>' ..
				'<td> ' .. devver .. '<br>' ..
				'</td>' ..
				'<td style="text-align: right;"><b>SSID</b><br>' ..
				'</td>' ..
				'<td> ' .. meu_ssid .. '<br>' ..
				'</td>' ..
				'</tr>' ..
				'<tr>' ..
				'<td style="text-align: right;"><b>Chip ID</b></td>' ..
				'<td> ' .. chipid .. '<br>' ..
				'</td>' ..
				'<td style="text-align: right;"><b>Wifi Mode</b><br>' ..
				'</td>' ..
				'<td> ' .. modo_wifi[wifi.getmode()] .. '<br>'
				conn:send(pagina)-- envia fragmento da pagina
				pagina = '</td>' ..
				'</tr>' ..
				'<tr>' ..
				'<td style="text-align: right;"><b>Flash ID</b></td>' ..
				'<td colspan="1"> ' .. flashid .. '<br>' ..
				'</td>' ..
				'</tr>' ..
				'<tr>' ..
				'<td style="text-align: right;"><b>Flash size</b></td>' ..
				'<td colspan="1"> ' .. flashsize .. ' Kbytes<br>' ..
				'</td>' ..
				'</tr>' ..
				'<tr>' ..
				'<td style="text-align: right;"><b>Flash mode</b></td>' ..
				'<td colspan="1"> ' .. flashmode .. '<br>' ..
				'</td>' ..
				'</tr>' ..
				'<tr>'
				conn:send(pagina)-- envia fragmento da pagina
				pagina = '<td style="text-align: right;"><b>Flash speed</b></td>' ..
				'<td colspan="1"> ' .. (flashspeed/1000/1000) .. ' MHz<br>' ..
				'</td>' ..
				'</tr>' ..
				'</tbody>' ..
				'</table>' ..
				'</div>' ..
				'<p style="text-align: center;"> Protótipo desenvolvido por <b>Marcelo Marques Da Rocha</b><br>' ..
				'Aluno do curso: <b>Tecnologia em Sistemas de Computação</b><br>' ..
				'Instituição: <b>CEDERJ / UFF </b><br>' ..
				'Ano: <b>2018</b></p>' ..
				'</body>' ..
				'</html>'
				conn:send(pagina)-- envia fragmento da pagina
			end
		)	
		-- registra a funcao que executa apos algo sser enviado			
		conn:on("sent",
			function(conn) 
				conn:close() -- fecha a conexao
			end
		)
	end
)
	
