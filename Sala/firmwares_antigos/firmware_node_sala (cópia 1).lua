-- Firmware do NodeSala
-- Autor: Marcelo Rocha
-- CEDERJ/Universidade Federal Fluminense
-- TCC 
-- Orientador: Luciano Bertini

pir_anterior = 0 -- define o estado inicial do sensor de movimento

led_presenca = 0 -- seta o pino 0 (led interno) como indicador de movimento
gpio.mode(led_presenca, gpio.OUTPUT) -- este pino funciona com logica invertida
gpio.write(led_presenca, gpio.HIGH)

pino_luz = 1 -- seta o pino 1 para a iluminacao principal
pwm.setup(pino_luz, 512, 0) -- config. pino, freq. e duty
pwm.start(pino_luz)

pino_arcon = 2 -- seta o pino 2 (led vermelho) para o ar condicionado
gpio.mode(pino_arcon, gpio.OUTPUT)
gpio.write(pino_arcon, gpio.LOW)

pino_umidade = 3 -- seta o pino 3 (led verde) para o umidificador
gpio.mode(pino_umidade, gpio.OUTPUT)
gpio.write(pino_umidade, gpio.LOW)

pino_DHT22 = 4 -- seta o pino 4 para o sensor de temp/umid (DHT22)

pino_pir = 5 -- seta o pino 5 para o PIR (Sensor de movimento)
gpio.mode(pino_pir, gpio.INPUT)

topico = {} -- fila de topicos
valor = {} -- fila de valores

function pisca_led_3x()
    -- pisca o led interno 3x indicando que inicializou corretamente
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
-- as tabelas funcionao com uma fila (FIFO)
function publicaTopico ()
    if (topico[1] ~= nil and valor[1] ~= nil) then -- primeiro topico da fila
        -- pub_status recebe true ou false indicando o sucesso da publicacao do topico
        pub_status = m:publish(topico[1], valor[1], 0, 0, function()
            --print(topico[1] .. " : " .. valor[1])
            table.remove(topico, 1) -- remove topico e valor
            table.remove(valor, 1)
        end)
        if pub_status == false then 
            print("Erro ao publicar......") 
        end
    else
        print("Fila vazia...") -- nao havia topicos na fila
    end
end

-- funcao que faz a leitura do sensor de movimento PIR
function lePIR()
    print("Estado WIFI... " .. wifi.sta.status())
    print("Lendo PIR...")
    presenca = gpio.read(pino_pir)
    
    if presenca == 0 then 
        gpio.write(led_presenca, 1)
    else
        gpio.write(led_presenca, 0) 
    end
    
    if pir_anterior ~= presenca then -- so publica se houver mudanca de estado
        table.insert(topico, "tccmrocha/sala/presenca")
        table.insert(valor,  presenca)
        pir_anterior = presenca -- inverte o estado
    end
end

-- funcao que faz a leitura do sensor de temperatura e umidade    
function leDHT22()
    print("Lendo DHT22...")
    status, temperatura, umidade, temp_decimal, umid_decimal = dht.read(pino_DHT22)
    table.insert(topico, "tccmrocha/sala/temperatura")
    table.insert(valor,  temperatura)
    table.insert(topico, "tccmrocha/sala/umidade")
    table.insert(valor,  umidade)   
end

-- cria o cliente mqtt com as opcoes especificadas
m = mqtt.Client("node-sala", 120, "marcelo", "mrbf8051")

-- setup Last Will and Testament
m:lwt("/lwt", "offline", 0, 0)

--m:on("connect", function(client) print ("On connect----------") end)

m:on("offline", function(client) 
    print ("offline.................") 
    tmr.unregister(0)
    tmr.unregister(1)
    tmr.unregister(2)
    end)

-- evento de recebimento de mensagem
m:on(
    "message", 
    function(client, topic, data) 
        print (topic .. " = " .. data)
        if topic == "tccmrocha/sala/umidificador" and data == "liga" then
            gpio.write(pino_umidade, gpio.HIGH) -- liga o umidificador
        end
        if topic == "tccmrocha/sala/umidificador" and data == "desliga" then
            gpio.write(pino_umidade, gpio.LOW) -- desliga o umidificador
        end
        if topic == "tccmrocha/sala/arcondicionado" and data == "liga" then
            gpio.write(pino_arcon, gpio.HIGH) -- liga o ar condicionado
        end
        if topic == "tccmrocha/sala/arcondicionado" and data == "desliga" then
            gpio.write(pino_arcon, gpio.LOW) -- desliga o ar condicionado
        end
        if topic == "tccmrocha/sala/luz" and data == "liga" then
            pwm.setduty(pino_luz, 1023) -- liga a luz
        end
        if topic == "tccmrocha/sala/luz" and data == "desliga" then
            pwm.setduty(pino_luz, 0) -- desliga a luz
        end
        if topic == "tccmrocha/sala/luz/intensidade" then
            pwm.setduty(pino_luz, data) -- seta o pwm da instensidade da luz
        end
        if topic == "tccmrocha/sala/reset" and data == "hardware" then 
            node.restart() -- reseta o dispotivo
        end
        if topic == "tccmrocha/all/pergunta" and data == "ping" then
            -- publica o o ip do dispositivo indicando que esta online
            m:publish("tccmrocha/all/resposta/sala", wifi.sta.getip().." - Online", 0, 0, function() 
              print("NodeMCU-Sala-OnLine")
            end)
        end       
    end
)

host = "tccmrocha.webhop.me" -- servico do mqtt broker (mosquitto) rodando no raspberry pi
porta_mqtt = 1883 -- porta onde roda o broker

-- conecta ao mqtt broker
m:connect(
    host, 
    porta_mqtt, 
    0, 
    function(client) -- se a conexao foi um sucesso entao assina os topicos
        print("Conectado ao mqtt broker...")
        print("Topicos assinados")
        print("-------------------------------")
        client:subscribe("tccmrocha/sala/luz", 0, function(client) 
            print("topico: tccmrocha/sala/luz OK")
            client:subscribe("tccmrocha/sala/luz/intensidade", 0, function(client) 
                print("topico: tccmrocha/sala/luz/intensidade OK")
                client:subscribe("tccmrocha/sala/arcondicionado", 0, function(client) 
                    print("topico: tccmrocha/sala/arcondicionado OK")
                    client:subscribe("tccmrocha/sala/umidificador", 0, function(client) 
                        print("topico: tccmrocha/sala/umidificador OK")
                        client:subscribe("tccmrocha/sala/reset", 0, function(client) 
                            print("topico: tccmrocha/sala/reset OK")
                            client:subscribe("tccmrocha/all/pergunta", 0, function(client) 
                                print("topico: tccmrocha/all/pergunta OK")
                                
                                -- pisca o led interno 3x indicando que inicializou corretamente
                                pisca_led_3x()

                                -- reseta a interface grafica
                                m:publish("tccmrocha/sala/reset", "interface_grafica", 0, 0)
                                
                                leDHT22() -- faz uma primeira leitura
            
                                ---[[
                                tmr.alarm( -- programa as leituras do dht22 para cada 15s
                                    0, 
                                    15000, 
                                    tmr.ALARM_AUTO,
                                    leDHT22
                                )
                                ---]]

                                ---[[
                                tmr.alarm( -- programa as leituras do PIR para cada 300ms
                                    1, 
                                    300, 
                                    tmr.ALARM_AUTO,
                                    lePIR
                                )
                                ---]]

                                ---[[
                                tmr.alarm( -- programa as publicacoes para cada 200ms
                                    2, 
                                    200, 
                                    tmr.ALARM_AUTO,
                                    publicaTopico
                                )
                                ---]]
                            end)
                        end)
                    end)
                end)
            end)
        end)      
       
    end,
    function(client, reason)
        print("failed reason: " .. reason)
    end
)
