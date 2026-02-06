using eCommerce.Model.Messages;
using eCommerce.Services;
using System.Threading;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Services
{
    /// <summary>
    /// No-op publisher when RabbitMQ is not configured. Reservation still saves; user just won't get a notification.
    /// </summary>
    public class NoOpReservationNotificationPublisher : IReservationNotificationPublisher
    {
        public Task PublishReservationStatusChangedAsync(ReservationStatusChangedMessage message, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
    }
}
