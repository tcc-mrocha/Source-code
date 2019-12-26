-- conecta ao wifi
-- conectando ao roteador

dofile("tabelas.lua") -- importa tabelas
dofile("credenciais.lua") -- importa tabela config com ssid e senha definida no arquivo credenciais.lua

wifi.setmode(wifi.STATION) -- define o modo da conexao wifi

wifi.sta.config(config) -- configura a conexao

print("Conectando ao wifi...")

-- tenta conectar a cada 1s
tmr.alarm(2, 1000, tmr.ALARM_AUTO, function ()
    if wifi.sta.getip() == nil
        then
            print("Estado WIFI... " .. estado_wifi[wifi.sta.status()])
            print("IP indisponivel, aguardando...") -- falha ao conectar
            
        else
            meu_ip = wifi.sta.getip()
            meu_mac = wifi.sta.getmac()
            print("Estado WIFI... " .. estado_wifi[wifi.sta.status()])
            print("Conectado, o IP é " .. meu_ip)
            print("O End. MAC é " .. meu_mac)
            tmr.unregister(2) -- libera o timer
            dofile("firmware_node_sala.lc") -- carregao firmware principal
    end
end)





