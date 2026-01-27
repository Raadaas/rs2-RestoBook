using System;

namespace eCommerce.Model.Responses
{
    public class ChatConversationResponse
    {
        public int Id { get; set; }

        /// <summary>
        /// Customer (mobile app) user id.
        /// </summary>
        public int UserId { get; set; }

        public string? UserName { get; set; }

        public int RestaurantId { get; set; }

        public string? RestaurantName { get; set; }

        public DateTime StartedAt { get; set; }

        public DateTime LastMessageAt { get; set; }

        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// Last message preview (optional convenience for conversation list UIs).
        /// </summary>
        public string? LastMessageText { get; set; }

        /// <summary>
        /// Unread messages count for the current caller (computed server-side).
        /// </summary>
        public int UnreadCount { get; set; }
    }
}

