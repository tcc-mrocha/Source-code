print("Iniciando o NodeMcu em 3s....")

-- essa pausa permite a exclusao do arquivo init.lua, caso seja necessario
-- para remover usar: file.remove("init.lua")
tmr.delay(3000000) -- 3s em microsegundos

dofile("conecta_wifi_banheiro.lc") -- carrega o arquivo que conecta ao wifi
