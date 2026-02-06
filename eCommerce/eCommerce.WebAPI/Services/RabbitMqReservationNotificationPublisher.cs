using EasyNetQ;
using eCommerce.Model.Messages;
using eCommerce.Services;
using System.Threading;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Services
{
    public class RabbitMqReservationNotificationPublisher : IReservationNotificationPublisher
    {
        private readonly IBus _bus;

        public RabbitMqReservationNotificationPublisher(IBus bus)
        {
            _bus = bus;
        }

        public Task PublishReservationStatusChangedAsync(ReservationStatusChangedMessage message, CancellationToken cancellationToken = default)
        {
            return _bus.PubSub.PublishAsync(message, cancellationToken);
        }
    }
}
