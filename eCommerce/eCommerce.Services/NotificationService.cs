using eCommerce.Model.Responses;
using eCommerce.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class NotificationService : INotificationService
    {
        private readonly eCommerceDbContext _context;

        public NotificationService(eCommerceDbContext context)
        {
            _context = context;
        }

        public async Task<List<NotificationResponse>> GetByUserIdAsync(int userId)
        {
            return await _context.Notifications
                .AsNoTracking()
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.SentAt)
                .Select(n => new NotificationResponse
                {
                    Id = n.Id,
                    UserId = n.UserId,
                    Type = n.Type,
                    Title = n.Title,
                    Message = n.Message,
                    RelatedReservationId = n.RelatedReservationId,
                    IsRead = n.IsRead,
                    SentAt = n.SentAt,
                    ReadAt = n.ReadAt
                })
                .ToListAsync();
        }

        public async Task MarkAsReadAsync(int notificationId, int userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

            if (notification == null)
                return;

            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
    }
}
