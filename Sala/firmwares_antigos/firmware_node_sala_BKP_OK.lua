-- Firmware do NodeSala
-- informacao sobre o dht22
    -- power supply: 3.3V – 6V DC
    -- output signal: single-bus
    -- sensing element: polymer humidity capacitor & DS18B20
    -- measuring range: humidity 0-100% RH / temperature -40°C – 125°C
    -- accuracy: humidity ±2% / temperature ±0.2°C
    -- sensing period: ~2s
    
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
            print("False") 
        end
    else
        print("Fila vazia...") -- nao havia topicos na fila
    end
end

-- funcao que faz a leitura do sensor de movimento PIR
function lePIR()
    print("lendo PIR...")
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
    print("lendo DHT22...")
    status, temperatura, umidade, temp_decimal, umid_decimal = dht.read(pino_DHT22)
    table.insert(topico, "tccmrocha/sala/temperatura")
    table.insert(valor,  temperatura)
    table.insert(topico, "tccmrocha/sala/umidade")
    table.insert(valor,  umidade)   
end

-- cria o cliente mqtt com as opcoes especificadas
m = mqtt.Client("node-sala", 120, "marcelo", "mrbf8051")

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("/lwt", "offline", 0, 0)

m:on("connect", function(client) print ("On connect----------") end)

m:on("offline", function(client) print ("offline") end)

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
        if topic == "tccmrocha/sala/reset" then
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

m:connect(
    host, 
    porta_mqtt, 
    0, 
    function(client) -- se a conexao foi um sucesso entao assina os topicos
        print("connected")
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
                                leDHT22() -- faz uma primeira leitura
            
                                ---[[
                                tmr.alarm( -- programa as leituras do dht22 para cada 30s
                                    0, 
                                    30000, 
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
