-- Firmware do NodeCisterna
-- Autor: Marcelo Rocha
-- CEDERJ/Universidade Federal Fluminense
-- TCC 
-- Orientador: Luciano Bertini

dofile("hcsr04-simple.lua")

node_nome = "node-cisterna" -- nomde do dispositivo
host = "192.168.0.50" --"tccmrocha.webhop.me" -- endereco do servidor mqtt broker (mosquitto) rodando no raspberry pi
porta_mqtt = 1883 -- porta onde roda o mosquitto
top_base = "tccmrocha/cisterna" -- topico base do dispositivo

meu_ssid, password, bssid_set, bssid = wifi.sta.getconfig()
majorver, minorver, devver, chipid, flashid, flashsize, flashmode, flashspeed = node.info()

led_presenca = 0

-- tabelas para os topicos e valores
topico = {} -- fila de topicos
valor = {} -- fila de valores

-- pisca o led interno 3x indicando que inicializou corretamente
function pisca_led_3x()
    print('\nIniciando Node - Piscando o LED\n')
    tmr.delay(300000)
    gpio.write(led_presenca, gpio.LOW)
    tmr.delay(300000)   
    gpio.write(led_presenca, gpio.HIGH)
    tmr.delay(300000)
    gpio.write(led_presenca, gpio.LOW)
    tmr.delay(300000)
    gpio.write(led_presenca, gpio.HIGH)
    tmr.delay(300000)
    gpio.write(led_presenca, gpio.LOW)
    tmr.delay(300000)   
    gpio.write(led_presenca, gpio.HIGH)
    tmr.delay(300000)
end

-- funcao que publica em um topico mqtt
-- ela le a tabela de topicos e valores e os publica um por vez
-- as tabelas funcionam como uma fila (FIFO)
function publicaTopico ()
    if (topico[1] ~= nil and valor[1] ~= nil) then -- primeiro topico da fila
        -- pub_status recebe true ou false indicando o sucesso da publicacao do topico
        pub_status = mqtt_cliente:publish(topico[1], valor[1], 0, 0, function()
            print('Publicando...')
            table.remove(topico, 1) -- remove topico e valor
            table.remove(valor, 1)
        end)
        if pub_status == false then 
            print("Erro ao publicar......") 
        end
    else
        --print("Fila de topicos vazia...") -- nao havia topicos na fila
    end
end

-- funcao que faz a leitura do sensor de temperatura e umidade    
function leDistancia()
    --print("\nEstado WIFI... " .. estado_wifi[wifi.sta.status()])
    --print("  IP: " .. wifi.sta.getip())
    --print("  SSID: " .. meu_ssid)

    measure()
    nivel_litros = 7500 - (50 * (math.ceil(distance * 100)))
    table.insert(topico, top_base .. "/nivel")
    table.insert(valor,  nivel_litros)
    print("Distance: "..string.format("%.2f", math.ceil(distance * 100)).." Readings: "..#readings)
end

-- cria o cliente mqtt com as opcoes especificadas
mqtt_cliente = mqtt.Client(nodeNome, 120, "marcelo", "mrbf8051")

-- setup Last Will and Testament
mqtt_cliente:lwt("/lwt", "offline", 0, 0)

--mqtt_cliente:on("connect", function(client) print ("On connect----------") end)

-- registra a callback que responde ao estado de offline
mqtt_cliente:on("offline", function(client) 
    print ("offline................................")
    print("reconectando..")
    tmr.unregister(0)
    tmr.unregister(1)
    tmr.unregister(2)
    tmr.alarm(
        0,
        2000,
        tmr.ALARM_SINGLE,
        conecta_servidor
    )
    end)

-- registra a callback de recebimento de mensagem
mqtt_cliente:on(
    "message", 
    function(client, topic, data)
        print (topic .. " = " .. data)
        if topic == top_base .. "/luz" and data == "liga" then
            pwm.setduty(pino_luz, 1023) -- liga a luz
        end
        if topic == top_base .. "/luz" and data == "desliga" then
            pwm.setduty(pino_luz, 0) -- desliga a luz
        end
        if topic == top_base .. "/reset" and data == "hardware" then 
            print("\nO dispositivo sera reiniciado em 2s...")
            for t = 0, 6 do
                tmr.unregister(t) -- para todos os timers
            end
            tmr.alarm(
                6,
                2000,
                tmr.ALARM_SINGLE,
                function() 
                    node.restart() -- reseta o dispotivo
                end
            )
        end
        if topic == "tccmrocha/all/pergunta" and data == "ping" then
            -- publica o o ip do dispositivo indicando que esta online
            mqtt_cliente:publish("tccmrocha/all/resposta/cisterna", wifi.sta.getip().." - Online", 0, 0, function() 
              print(node_nome .. "-OnLine")
            end)
        end       
    end
)

-- conecta ao mqtt broker
function conecta_servidor()
	-- registra a callback de conexao com o servodor mqtt
	mqtt_cliente:connect(
	    host, 
	    porta_mqtt, 
	    0, 
	    function(client) -- se a conexao foi um sucesso entao assina os topicos
	        print("Conectado ao mqtt broker...")
	        print("Topicos assinados")
	        print("-------------------------------")
	        -- cada topico e' assinado a partir do sucesso do anterior
	        client:subscribe(top_base .. "/luz", 0, function(client) 
	            print("Topico: " .. top_base .. "/luz OK")
				client:subscribe(top_base .. "/reset", 0, function(client) 
					print("Topico: " .. top_base .. "/reset OK")
					client:subscribe("tccmrocha/all/pergunta", 0, function(client) 
						print("Topico: tccmrocha/all/pergunta OK")
						
						-- pisca o led interno 3x indicando que inicializou corretamente
						pisca_led_3x()

						-- reseta a interface grafica
						mqtt_cliente:publish(top_base .. "/reset", "interface_grafica", 0, 0)
						
						leDistancia() -- faz uma primeira leitura

						---[[
						tmr.alarm( -- programa as leituras do dht22 para cada 15s
							0, 
							5000, 
							tmr.ALARM_AUTO,
							leDistancia
						)
						---]]

						---[[
						tmr.alarm( -- programa as publicacoes para cada 200ms
							2, 
							2000, 
							tmr.ALARM_AUTO,
							publicaTopico
						)
						---]]
					end)
				end)
	        end)      	       
	    end,
	    function(client, reason)
	        print("Falha ao conectar..................")
	        print("Razao da falha: " .. err_conn[reason]) -- indice na tabela de erro
	        print("Reconectando..")
	        -- desliga todos os timers
	        tmr.unregister(0)
	        tmr.unregister(1)
	        tmr.unregister(2)
	        tmr.alarm(
	            0,
	            2000,
	            tmr.ALARM_SINGLE,
	            conecta_servidor
	        )
	    end
	)
end

print("\n" .. node_nome .. "............") -- imprime o nome do dispositivo

--dofile("node_http_server.lc") -- roda o servidor http

--dofile("node_telnet_server.lc") -- roda o servidor telnet 

-- chama a funcao que conecta ao mqtt broker
tmr.alarm(
    0,
    1000,
    tmr.ALARM_SINGLE,
    conecta_servidor
)
