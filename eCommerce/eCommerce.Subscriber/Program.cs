using EasyNetQ;
using eCommerce.Model.Messages;
using eCommerce.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

// Load configuration (same pattern as WebAPI for connection string)
var config = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: true)
    .AddJsonFile("appsettings.Development.json", optional: true)
    .Build();

var connectionString = config.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Database=rs2RestoBook;Trusted_Connection=True;TrustServerCertificate=True";
var rabbitMqConnectionString = config["RabbitMQ"] ?? "host=localhost";

var dbContextOptions = new DbContextOptionsBuilder<eCommerceDbContext>()
    .UseSqlServer(connectionString)
    .Options;

var bus = RabbitHutch.CreateBus(rabbitMqConnectionString);

await bus.PubSub.SubscribeAsync<ReservationStatusChangedMessage>(
    "reservation_status_notifications",
    async msg =>
    {
        var (title, message) = BuildNotificationText(msg);
        await using var context = new eCommerceDbContext(dbContextOptions);
        context.Notifications.Add(new Notification
        {
            UserId = msg.UserId,
            Type = "ReservationStatusChanged",
            Title = title,
            Message = message,
            RelatedReservationId = msg.ReservationId,
            IsRead = false,
            SentAt = DateTime.UtcNow
        });
        await context.SaveChangesAsync();
    });

Console.WriteLine("Subscriber listening for reservation status changes. Press any key to exit.");
Console.ReadKey();

static (string Title, string Message) BuildNotificationText(ReservationStatusChangedMessage msg)
{
    var dateStr = msg.ReservationDate.ToString("yyyy-MM-dd");
    var timeStr = $"{msg.ReservationTime.Hours:D2}:{msg.ReservationTime.Minutes:D2}";
    var place = string.IsNullOrWhiteSpace(msg.RestaurantName) ? "your reservation" : msg.RestaurantName;

    return msg.NewState switch
    {
        "Confirmed" => (
            "Reservation confirmed",
            $"Your reservation at {place} on {dateStr} at {timeStr} has been confirmed."
        ),
        "Cancelled" => (
            "Reservation cancelled",
            string.IsNullOrWhiteSpace(msg.CancellationReason)
                ? $"Your reservation at {place} on {dateStr} at {timeStr} has been cancelled."
                : $"Your reservation at {place} on {dateStr} at {timeStr} has been cancelled. Reason: {msg.CancellationReason}"
        ),
        "Completed" => (
            "Reservation completed",
            $"Your reservation at {place} on {dateStr} at {timeStr} has been marked as completed. Thank you!"
        ),
        _ => (
            "Reservation update",
            $"Your reservation at {place} on {dateStr} at {timeStr} is now {msg.NewState}."
        )
    };
}
