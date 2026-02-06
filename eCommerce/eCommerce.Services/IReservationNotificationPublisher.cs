using eCommerce.Model.Messages;
using System.Threading;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    /// <summary>
    /// Publishes reservation status change events (e.g. to RabbitMQ) so consumers can notify the user.
    /// </summary>
    public interface IReservationNotificationPublisher
    {
        Task PublishReservationStatusChangedAsync(ReservationStatusChangedMessage message, CancellationToken cancellationToken = default);
    }
}
