using MetriqusSdk.Web;
import "dart:core";

// namespace MetriqusSdk
{
    internal static class EventRequestSender
    {
        static async Future<bool> PostEventBatch(String eventsJson)
        {
            try
            {
                //Metriqus.DebugLog("Posting Event Batch: " + eventsJson);

                var metriqusSettings = Metriqus.GetMetriqusSettings();

                var remoteSettings = Metriqus.GetMetriqusRemoteSettings();

                if (remoteSettings == null || String.IsNullOrEmpty(remoteSettings.EventPostUrl))
                {
                    Metriqus.DebugLog("Can't find the event post url", LogType.Warning);
                    return false;
                }
                else
                {
                    String timestamp = MetriqusJSON.SerializeValue(DateTimeOffset.UtcNow.ToUnixTimeSeconds());

                    String encryptedBody = Encrypt(eventsJson, metriqusSettings.ClientSecret, metriqusSettings.ClientKey);

                    String signature = CreateHmacSignature(metriqusSettings.ClientKey, metriqusSettings.ClientSecret, encryptedBody, timestamp);

                    var headers = new Dictionary<string, string>();

                    RequestSender.AddContentType(headers, RequestSender.ContentTypeJson);
                    RequestSender.AddAccept(headers, RequestSender.ContentTypeJson);
                    RequestSender.AddCustomHeader(headers, "ClientKey", metriqusSettings.ClientKey);
                    RequestSender.AddCustomHeader(headers, "Signature", signature);
                    RequestSender.AddCustomHeader(headers, "Timestamp", timestamp);

                    String encryptedJsonData = $"{{ \"encryptedData\": \"{encryptedBody}\" }}";

                    //Metriqus.DebugLog("encryptedJsonData: " + encryptedJsonData);

                    var response = await RequestSender.PostAsync(remoteSettings.EventPostUrl, encryptedJsonData, headers);

                    if (response.IsSuccess)
                    {
                        MetriqusResponseObject mro = MetriqusResponseObject.Parse(response.Data);

                        return mro.IsSuccess;
                    }
                    else
                    {
                        foreach (var error in response.Errors)
                        {
                            Metriqus.DebugLog($"Sending events failed. Error: {error}, message: {response.Data}", LogType.Error);
                        }
                        return false;
                    }
                }
            }
            catch (Exception e)
            {
                Metriqus.DebugLog($"Sending events failed. Error: {e.Message}", LogType.Error);

                return false;
            }
        }

        // private static String CreateHmacSignature(String clientKey, String clientSecret, String encryptedBody, String timestamp)
        {
            String data = $"{clientKey}{timestamp}{encryptedBody}";
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(clientSecret));
            byte[] hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
            return Convert.ToBase64String(hash);
        }

        // private static String Encrypt(String plainText, String _clientSecret, String _clientKey)
        {
            using var aes = Aes.Create();
            aes.Key = GenerateAESKey(_clientSecret);
            aes.IV = GenerateAESIV(_clientKey);
            aes.Mode = CipherMode.CBC;
            aes.Padding = PaddingMode.PKCS7;

            using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
            using var ms = new MemoryStream();
            using var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write);
            using var sw = new StreamWriter(cs);

            sw.Write(plainText);
            sw.Flush();
            cs.FlushFinalBlock();

            return Convert.ToBase64String(ms.ToArray());
        }

        // private static byte[] GenerateAESKey(String secret)
        {
            using var sha256 = SHA256.Create();
            byte[] hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(secret));
