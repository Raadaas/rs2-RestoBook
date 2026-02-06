using eCommerce.Model.Responses;
using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationsController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        /// <summary>
        /// Get all notifications for the current user (newest first).
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<List<NotificationResponse>>> GetMyNotifications()
        {
            var userId = GetCurrentUserId();
            var list = await _notificationService.GetByUserIdAsync(userId);
            return Ok(list);
        }

        /// <summary>
        /// Mark a notification as read.
        /// </summary>
        [HttpPatch("{id}/read")]
        public async Task<ActionResult> MarkAsRead(int id)
        {
            var userId = GetCurrentUserId();
            await _notificationService.MarkAsReadAsync(id, userId);
            return NoContent();
        }

        private int GetCurrentUserId()
        {
            var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(idStr) || !int.TryParse(idStr, out var id))
                throw new ArgumentException("Invalid user identity.");
            return id;
        }
    }
}
