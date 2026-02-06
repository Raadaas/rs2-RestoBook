using eCommerce.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public interface INotificationService
    {
        Task<List<NotificationResponse>> GetByUserIdAsync(int userId);
        Task MarkAsReadAsync(int notificationId, int userId);
    }
}
