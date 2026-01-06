using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace eCommerce.WebAPI.Converters
{
    public class TimeSpanConverter : JsonConverter<TimeSpan>
    {
        public override TimeSpan Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.String)
            {
                var value = reader.GetString();
                if (TimeSpan.TryParse(value, out var timeSpan))
                {
                    return timeSpan;
                }
            }
            else if (reader.TokenType == JsonTokenType.StartObject)
            {
                // Handle object format like {"ticks": 72000000000}
                using (var doc = JsonDocument.ParseValue(ref reader))
                {
                    if (doc.RootElement.TryGetProperty("ticks", out var ticksElement))
                    {
                        var ticks = ticksElement.GetInt64();
                        return TimeSpan.FromTicks(ticks);
                    }
                    if (doc.RootElement.TryGetProperty("hours", out var hoursElement))
                    {
                        var hours = hoursElement.GetInt32();
                        return TimeSpan.FromHours(hours);
                    }
                }
            }
            
            return TimeSpan.Zero;
        }

        public override void Write(Utf8JsonWriter writer, TimeSpan value, JsonSerializerOptions options)
        {
            // Write as string in format "HH:mm:ss" or "d.HH:mm:ss" if days > 0
            if (value.Days > 0)
            {
                writer.WriteStringValue(value.ToString(@"d\.hh\:mm\:ss"));
            }
            else
            {
                writer.WriteStringValue(value.ToString(@"hh\:mm\:ss"));
            }
        }
    }
}

