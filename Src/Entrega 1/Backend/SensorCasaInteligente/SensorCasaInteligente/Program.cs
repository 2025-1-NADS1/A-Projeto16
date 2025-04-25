using System;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Globalization;

public class ServidorCasaInteligenteThreads
{
    private static TcpListener tcpListener;
    private static readonly int port = 12345;
    private static readonly CultureInfo cultureInfo = CultureInfo.InvariantCulture; // Garante o ponto como separador decimal

    public static void Main(string[] args)
    {
        tcpListener = new TcpListener(IPAddress.Any, port);
        try
        {
            tcpListener.Start();
            Console.WriteLine("[INFO] Servidor iniciado na porta " + port);

            while (true)
            {
                TcpClient client = tcpListener.AcceptTcpClient();
                Thread clientThread = new Thread(() => HandleClient(client));
                clientThread.Start();
            }
        }
        catch (SocketException ex)
        {
            Console.WriteLine($"[ERRO] Erro ao iniciar o servidor: {ex.Message}");
        }
        finally
        {
            tcpListener?.Stop(); // Garante que o listener seja parado
        }
    }

    private static void HandleClient(TcpClient client)
    {
        using (NetworkStream stream = client.GetStream())
        using (StreamReader reader = new StreamReader(stream, Encoding.UTF8))
        using (StreamWriter writer = new StreamWriter(stream, Encoding.UTF8) { AutoFlush = true })
        {
            try
            {
                Console.WriteLine($"[INFO] Cliente conectado: {client.Client.RemoteEndPoint}");
                while (client.Connected)
                {
                    string json = reader.ReadLine();
                    if (string.IsNullOrEmpty(json))
                    {
                        Console.WriteLine($"[INFO] Cliente desconectou: {client.Client.RemoteEndPoint}");
                        break;
                    }

                    Console.WriteLine($"[RECV] Do Cliente {client.Client.RemoteEndPoint}: {json}");

                    SensorData data;
                    try
                    {
                        data = JsonSerializer.Deserialize<SensorData>(json);

                        // Formatar a saída da temperatura e umidade
                        string tempFormatted = data.Temperatura.ToString("F1", cultureInfo);
                        string umidFormatted = data.Umidade.ToString("F1", cultureInfo);

                        Console.WriteLine($"[PROC] Dados do Sensor {data.ID_Sensor}: Temp={tempFormatted} ºC, Umid={umidFormatted} %, Mov={data.Movimento}");
                    }
                    catch (JsonException ex)
                    {
                        Console.WriteLine($"[ERRO] Erro ao desserializar JSON: {ex.Message}, JSON: {json}");
                        continue;
                    }

                    // Simula o envio de um comando de volta ao sensor
                    var command = new { Command = "Atualizar", Time = DateTime.Now };
                    string commandJson = JsonSerializer.Serialize(command);
                    writer.WriteLine(commandJson); // Usar StreamWriter
                    Console.WriteLine($"[SEND] Para Cliente {client.Client.RemoteEndPoint}: {commandJson}");
                }
            }
            catch (IOException ex)
            {
                Console.WriteLine($"[ERRO] Erro de E/S com o cliente {client.Client.RemoteEndPoint}: {ex.Message}");
            }
            catch (JsonException ex)
            {
                Console.WriteLine($"[ERRO] Erro ao processar JSON: {ex.Message}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ERRO] Erro na comunicação com o cliente {client.Client.RemoteEndPoint}: {ex.Message}");
            }
            finally
            {
                Console.WriteLine($"[INFO] Conexão fechada com {client.Client.RemoteEndPoint}");
                client?.Close(); // Garante que o cliente seja fechado
            }
        }
    }

    //Removido ReceiveJson e SendJson e usado StreamReader e StreamWriter

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

    private static void SendJson(NetworkStream stream, string json)
    {
        byte[] bytes = Encoding.UTF8.GetBytes(json + "\\n");
        stream.Write(bytes, 0, bytes.Length);
        stream.Flush();
    }
}