using System;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Threading;

public class ServidorCasaInteligenteThreads
{
    private static IPAddress serverIP;
    private static TcpListener tcpListener;
    private static readonly int port = 12345;

    public static void Main(string[] args)
    {
        // Tenta obter o endereço IP da máquina local
        try
        {
            string hostName = Dns.GetHostName();
            IPHostEntry hostEntry = Dns.GetHostEntry(hostName);
            foreach (IPAddress ip in hostEntry.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork) // Filtra para IPv4
                {
                    serverIP = ip;
                    break;
                }
            }

            // Se não conseguiu obter um endereço IPv4, usa o localhost como fallback
            if (serverIP == null)
            {
                serverIP = IPAddress.Loopback; // Equivalente a 127.0.0.1
                Console.WriteLine("[AVISO] Não foi possível determinar o IP local. Usando localhost.");
            }
        }
        catch (Exception ex)
        {
            serverIP = IPAddress.Loopback; // Fallback em caso de erro
            Console.WriteLine($"[ERRO] Erro ao obter informações de IP: {ex.Message}. Usando localhost.");
        }

        tcpListener = new TcpListener(serverIP, port);
        tcpListener.Start();

        Console.WriteLine($"[INFO] Servidor iniciado no IP: {serverIP} e porta {port}");

        while (true)
        {
            TcpClient client = tcpListener.AcceptTcpClient();
            Thread clientThread = new Thread(() => HandleClient(client));
            clientThread.Start();
        }
    }

    private static void HandleClient(TcpClient client)
    {
        using (NetworkStream stream = client.GetStream())
        {
            try
            {
                Console.WriteLine($"[INFO] Cliente conectado: {client.Client.RemoteEndPoint}");
                while (client.Connected) // Verificação de conexão
                {
                    string json = ReceiveJson(stream);
                    if (string.IsNullOrEmpty(json))
                    {
                        Console.WriteLine($"[INFO] Cliente desconectou: {client.Client.RemoteEndPoint}");
                        break;
                    }

                    SensorData data;
                    try
                    {
                        data = JsonSerializer.Deserialize<SensorData>(json);
                        Console.WriteLine($"[RECV] Do Cliente {client.Client.RemoteEndPoint}: {json}");
                        Console.WriteLine($"[PROC] Dados do Sensor {data.ID_Sensor}: " +
                                          $"Temp={data.Temperatura}, Umid={data.Umidade}, Mov={data.Movimento}");
                    }
                    catch (JsonException ex)
                    {
                        Console.WriteLine($"[ERRO] Erro ao desserializar JSON: {ex.Message}, JSON: {json}");
                        continue; // Próxima iteração para não travar
                    }


                    // Simula o envio de um comando de volta ao sensor
                    var command = new { Command = "Atualizar", Time = DateTime.Now };
                    string commandJson = JsonSerializer.Serialize(command);
                    SendJson(stream, commandJson);
                    Console.WriteLine($"[SEND] Para Cliente {client.Client.RemoteEndPoint}: {commandJson}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ERRO] Erro na comunicação com o cliente {client.Client.RemoteEndPoint}: {ex.Message}");
            }
            finally
            {
                client.Close();
                Console.WriteLine($"[INFO] Conexão fechada com {client.Client.RemoteEndPoint}");
            }
        }
    }

    private static void SendJson(NetworkStream stream, string json)
    {
        byte[] bytes = Encoding.UTF8.GetBytes(json + "\n"); // Adiciona um delimitador de nova linha
        stream.Write(bytes, 0, bytes.Length);
        stream.Flush(); // Garante que os dados são enviados imediatamente
    }

    private static string ReceiveJson(NetworkStream stream)
    {
        using (var reader = new System.IO.StreamReader(stream, Encoding.UTF8, leaveOpen: true))
        {
            try
            {
                return reader.ReadLine();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ERRO] Erro ao ler do stream: {ex.Message}");
                return string.Empty;
            }
        }
    }
}

// Defina a classe SensorData para a desserialização do JSON
public class SensorData
{
    public int ID_Sensor { get; set; }
    public double Temperatura { get; set; }
    public double Umidade { get; set; }
    public bool Movimento { get; set; }
}